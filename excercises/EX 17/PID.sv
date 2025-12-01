module PID 
#(parameter fast_sim = 1)
(
    input logic clk,
    input logic rst_n,
    input logic vld,
    input logic pwr_up,
    input logic rider_off,
    input logic signed [15:0] ptch,
    input logic signed [15:0] ptch_rt,
    output logic signed [11:0] PID_cntrl,
    output logic [7:0] ss_tmr
);
     
    localparam signed P_COEFF = 5'sd9;
    // ptch error saturated to signed 10-bit (-512 .. +511)
    logic signed [9:0] ptch_err_sat;
    logic signed [14:0] P_term;
    logic signed [14:0] I_term;
    logic signed [12:0] D_term;
    logic signed [17:0] integrator;
    logic ov;
    logic [26:0] long_tmr;
    logic signed [17:0] integrator_next;
    logic signed [17:0] ptch_ext;
    logic signed [17:0] PID_sum;
    // temporaries for fast_sim I_term saturation will be local to the always_comb below

    // Saturate ptch to signed 10-bit (-512..+511) using plain decimal constants
    always_comb begin
        if (ptch > 16'sd511)
            ptch_err_sat = 10'sd511;
        else if (ptch < -16'sd512)
            ptch_err_sat = -10'sd512; // assign via decimal negative constant
        else
            ptch_err_sat = ptch[9:0];
    end

    // Sign-extend error to integrator width and compute next integrator
    assign ptch_ext = {{8{ptch_err_sat[9]}}, ptch_err_sat};
    assign integrator_next = integrator + ptch_ext;
    // Overflow detection: operands same sign but result sign differs
    assign ov = (integrator[17] == ptch_ext[17]) && (integrator_next[17] != integrator[17]);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || !pwr_up || rider_off)
            integrator <= 18'sd0;
        else if (vld) begin
            if (ov)
                integrator <= integrator;  
            else
                integrator <= integrator_next;
        end
    end

    // Single combinational block: choose behavior at runtime/elaboration based on fast_sim
    always_comb begin
        // Signed P term
        P_term = $signed(ptch_err_sat) * P_COEFF; // fits within 15 bits

        if (fast_sim) begin
            // Under fast_sim: tap integrator[15:1] for I_term with saturation based on bits [17:15]
            logic signed [14:0] tmp_i;
            logic [2:0] tb;
            tb = integrator[17:15];
            if (tb == 3'b000) begin
                tmp_i = integrator[15:1];
            end else if (tb == 3'b111) begin
                tmp_i = integrator[15:1];
            end else if (integrator[17] == 1'b0) begin
                tmp_i = 15'sd16383;
            end else begin
                tmp_i = -15'sd16384;
            end
            I_term = tmp_i;
        end else begin
            // Normal behavior: I term is integrator >> 6 (12 bits) sign-extended to 15 bits
            I_term = {{3{integrator[17]}}, integrator[17:6]};
        end

        // D term: negative derivative, arithmetic right shift
        D_term = - (ptch_rt >>> 6);

        // Sum into wider signed accumulator to avoid accidental truncation
        PID_sum = $signed(P_term) + $signed(I_term) + $signed({{2{D_term[12]}}, D_term});

        PID_cntrl = (PID_sum > 18'sd2047) ? 12'sd2047 :
                    (PID_sum < -18'sd2048) ? -12'sd2048 : PID_sum[11:0];
    end
  
    // long_tmr is driven by the generate block below (normal or fast_sim)

    // Replace earlier empty generate: conditionally increment long_tmr faster in simulation
    generate
        if (fast_sim) begin
            // Fast sim: increment by 256 each clock (adds 8 LSBs)
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n || !pwr_up)
                    long_tmr <= 27'd0;
                else if (~&long_tmr[26:19]) // only increment while upper 8 bits not all ones
                    long_tmr <= long_tmr + 27'd256;
                else
                    long_tmr <= long_tmr; // freeze (one-shot)
            end
        end else begin
            // Default behavior: increment by 1 each clock
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n || !pwr_up)
                    long_tmr <= 27'd0;
                else if (~&long_tmr[26:19]) // only increment while upper 8 bits not all ones
                    long_tmr <= long_tmr + 27'd1;
                else
                    long_tmr <= long_tmr; // freeze (one-shot)
            end
        end
    endgenerate

    // expose top 8 bits as the subsystem timer
    assign ss_tmr = long_tmr[26:19];

    





    
endmodule