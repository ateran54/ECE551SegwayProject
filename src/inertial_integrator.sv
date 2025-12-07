// Team Turtle
module inertial_integrator 
(
    input  logic               clk,
    input  logic               rst_n,
    input  logic               vld,    //High for a single clock cycle when new inertial readings are valid.
    input  logic signed [15:0] ptch_rt, //16-bit signed raw pitch rate from inertial sensor
    input  logic signed [15:0] AZ,  //Will be used for sensor fusion (acceleration in Z direction)
    output logic signed [15:0] ptch //Fully compensated and “fused” 16-bit signed pitch.
);

// Pitch integrating accumulator (signed 27-bit)
logic signed [26:0] ptch_int; // This is the register ptch_rt is summed into

// Constant offsets
localparam logic signed [15:0] PTCH_RT_OFFSET = 16'h0050;
localparam logic signed [15:0] AZ_OFFSET      = 16'h00A0;

// Computed compensated pitch-rate (signed)
logic signed [15:0] ptch_rt_comp;
logic signed [26:0] ptch_rt_comp_ext;

// Accelerometer fusion signals
logic signed [15:0] AZ_comp;                 // AZ - AZ_OFFSET
logic signed [25:0] ptch_acc_product;        // product before shifting
logic signed [15:0] ptch_acc;                // accel-derived pitch (signed)
logic signed [26:0] fusion_ptch_offset;      // +/-1024 extended to 27 bits

// Compute compensated rate and sign-extend
assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
assign ptch_rt_comp_ext = { {11{ptch_rt_comp[15]}}, ptch_rt_comp };

    // Accelerometer-based pitch calculation
assign AZ_comp = AZ - AZ_OFFSET;
    // Multiply by fudge factor 327. Product width: 16+9=25 -> use 26 bits to be safe
//pipeline the multiplier for ptch_acc_product
assign ptch_acc_product = AZ_comp * $signed(327);

logic signed [25:0] ptch_acc_product_pipelined;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ptch_acc_product_pipelined <= '0;
    end else begin
        ptch_acc_product_pipelined <= ptch_acc_product;
    end
end

    // Shift down and sign-extend to 16 bits: take bits [25:13] and extend with 3 MSBs
assign ptch_acc = {{3{ptch_acc_product_pipelined[25]}}, ptch_acc_product_pipelined[25:13]};
    // Determine fusion offset direction
assign fusion_ptch_offset = (ptch_acc > ptch) ? 27'sd1024 : -27'sd1024;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ptch_int <= '0;
        ptch     <= '0;
    end else begin
        if (vld) begin
            ptch_int <= ptch_int - ptch_rt_comp_ext + fusion_ptch_offset;
        end
        // Output is bits [26:11] (divide by 2^11)
        ptch <= ptch_int[26:11];
    end
end
endmodule