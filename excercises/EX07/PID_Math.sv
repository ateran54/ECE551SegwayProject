module PID_Math (
    input logic signed [15:0] ptch,
    input logic signed [15:0] ptch_rt,
    input  logic signed [17:0] integrator,
    output logic signed [11:0] PID_cntrl
);
    localparam logic signed [4:0] P_COEFF = 5'h09;
    logic signed [9:0] ptch_err_sat;
    logic signed [14:0] P_term;
    logic signed [14:0] I_term;
    logic signed [12:0] D_term;
    logic signed [15:0] PID_cntrl_full;

    assign ptch_err_sat = ((&ptch[15]) && (~&ptch[14:9])) ? 10'h200 :
                            (((~&ptch[15]) && (&ptch[14:9])) ? 10'h1FF : ptch[9:0]);
    assign P_term = ptch_err_sat * P_COEFF;

    assign I_term = integrator >>> 6;

    assign D_term = ~(ptch_rt >>> 6) + 1;

    // Sign extend to 16 bits
    logic signed [15:0] P_term_ext, I_term_ext, D_term_ext;
    assign P_term_ext = { {1{P_term[14]}}, P_term };
    assign I_term_ext = { {1{I_term[14]}}, I_term };
    assign D_term_ext = { {3{D_term[12]}}, D_term };

    assign PID_cntrl_full = P_term_ext + I_term_ext + D_term_ext;
    assign PID_cntrl = ((&PID_cntrl_full[15]) && (~&PID_cntrl_full[14:11])) ? 12'h800 :
                            ((~&PID_cntrl_full[15]) && (&PID_cntrl_full[14:11])) ? 12'h7FF : PID_cntrl_full[11:0];




    
endmodule