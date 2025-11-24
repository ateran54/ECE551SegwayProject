module PID #(parameter fast_sim = 1) (
    input logic clk,                     // System clock
    input logic rst_n,                   // Active low reset
    input logic vld,                   // Signal that tells us if the next sample for our integrator is vld
    input logic pwr_up,
    input logic rider_off,
    input  logic signed [15:0] ptch,        // Signed 16-bit pitch signal from inertial_interface
    input  logic signed [15:0] ptch_rt,     // Signed 16-bit pitch rate from inertial_interface (D-term)
    output logic signed [11:0] PID_cntrl,    // 12-bit signed result of PID control
    output logic [7:0] ss_tmr
);

    // --- Saturation Module ---
    // Saturate 16-bit ptch to 10-bit signed
    logic signed [9:0]  ptch_err_sat;
    assign ptch_err_sat = ptch[15] ? (&ptch[14:9] ? ptch[9:0] : 10'h200) : (|ptch[14:9] ? 10'h1FF : ptch[9:0]);
    

    // --- Integrator ---
    logic signed [17:0] integrator;  // Signed 18-bit integrator to prevent overflow
    logic signed [17:0] integrator_next;
    assign integrator_next = integrator + $signed({{8{ptch_err_sat[9]}}, ptch_err_sat}); // Sign-extend ptch_err_sat to 18 bits
    logic should_accumulate;
    assign should_accumulate = vld & ((integrator[17] != ptch_err_sat[9]) || (integrator[17] && ptch_err_sat[9] && integrator_next[17]) || (~integrator[17] && ~ptch_err_sat[9] && ~integrator_next[17])); // Prevent overflow by checking sign bits
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            integrator <= 18'sd0;
        end else if (rider_off) begin
            integrator <= 18'sd0;
        end else if (should_accumulate) begin
            integrator <= integrator_next;
        end
    end

    //Timer
    logic [26:0] ss_counter;
    generate
        if (fast_sim) begin : fast_sim_block
            // This block is used when fast_sim is true
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) begin
                    ss_counter <= 27'd0;
                end else if (pwr_up) begin
                    if (~&ss_counter[26:19]) begin
                        ss_counter <= ss_counter + 27'd256; // Faster increment for simulation
                    end
                end else begin
                    ss_counter <= 27'd0; // Reset counter when power is down
                end
            end
        end else begin : normal_sim_block
            // This block is used when fast_sim is false
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) begin
                    ss_counter <= 27'd0;
                end else if (pwr_up) begin
                    if (~&ss_counter[26:19]) begin
                        ss_counter <= ss_counter + 27'd1; // Normal increment
                    end
                end else begin
                    ss_counter <= 27'd0; // Reset counter when power is down
                end
            end
        end
    endgenerate

    assign ss_tmr = ss_counter[26:19];

    // --- Constants ---
    localparam P_COEFF = 5'h09;  // Proportional gain

    // --- Intermediate Signals ---
    logic signed [14:0] P_term;
    logic signed [14:0] I_term;
    logic signed [12:0] D_term;
    logic signed [15:0] PID_SUM_16;



    // --- Proportional Term ---
    assign P_term = ptch_err_sat * $signed(P_COEFF); 

    // --- Integral Term ---
    generate if (fast_sim) begin
        assign I_term = integrator[17] ? (&integrator[17:15] ? integrator[15:1] : 15'sh4000) 
                               : (|integrator[16:15] ? 15'sh3FFF : integrator[15:1]);
    end else begin
        assign I_term = {{3{integrator[17]}}, integrator[17:6]};  // Divide by 64 (shift right 6)
    end
    endgenerate
    

    // --- Derivative Term ---
    assign D_term = $signed(-1)*(ptch_rt >>> 6);  // D_term is signed [12:0]

    // --- PID Sum ---
    assign PID_SUM_16 = P_term + I_term + D_term;

    // --- Output Saturation ---
    assign PID_cntrl = PID_SUM_16[15] ? 
                        ( &PID_SUM_16[14:11] ? PID_SUM_16[11:0] : 12'h800) : 
                        ( |PID_SUM_16[14:11] ? 12'h7FF : PID_SUM_16[11:0]);

endmodule