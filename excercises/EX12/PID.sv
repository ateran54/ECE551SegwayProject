module PID (
    input logic clk,
    input logic rst_n,
    input logic vld,
    input logic pwr_up,
    input logic rider_off,
    input logic signed [15:0] ptch,
    input logic signed [15:0] ptch_rt,
    output logic [11:0] PID_cntrl,
    output logic [7:0] ss_tmr
);
    localparam signed P_COEFF = 5'h09;
    logic signed [9:0] ptch_err_sat;
    logic [14:0] P_term;
    logic [14:0] I_term;
    logic [12:0] D_term;
    logic signed [15:0] PID_cntrl_full;
    logic [17:0] integrator;
    logic ov;
    logic [26:0] long_tmr;
    logic signed [17:0] integrator_next;

    assign ptch_err_sat = ((&ptch[15]) && (~&ptch[14:9])) ? 10'h200 :
                            ((~&ptch[15]) && (&ptch[14:9])) ? 10'h1FF : ptch[9:0];
    
    
    // Check if sign of result matches operands
    assign ov = (integrator[17] == {{8{ptch_err_sat[9]}}, ptch_err_sat}[17]) &&
                      (integrator_next[17] != integrator[17]);
    assign integrator_next = integrator + {{8{ptch_err_sat[9]}}, ptch_err_sat};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || !pwr_up || rider_off)
            integrator <= 18'h00000;
        else if (vld) begin
            if (ov)
                integrator <= integrator;  
            else
                integrator <= integrator_next;
        end
    end

    always_comb begin 
        P_term = ptch_err_sat * P_COEFF;
        I_term = integrator[17:6];
        D_term = -(ptch_rt >>> 6);

         // Sign extend to 16 bits
        P_term = {{P_term[14]}, P_term};
        I_term = {{I_term[14]}, I_term};
        D_term = {{3{D_term[12]}}, D_term};

        PID_cntrl_full = P_term + I_term + D_term;
        PID_cntrl = ((&PID_cntrl_full[15]) && (~&PID_cntrl_full[14:11])) ? 12'h800 :
                            ((~&PID_cntrl_full[15]) && (&PID_cntrl_full[14:11])) ? 12'h7FF : PID_cntrl_full[11:0];
    end
    

    
     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || !pwr_up)
            long_tmr <= 27'd0;
        else if (~&long_tmr[26:19]) // only increment while upper 8 bits not all ones
            long_tmr <= long_tmr + 27'd1;
        else
            long_tmr <= long_tmr; // freeze (one-shot)
    end
    assign ss_tmr = long_tmr[26:19];

    





    
endmodule