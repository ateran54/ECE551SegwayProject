module balance_cntrl #(parameter fast_sim = 1)(
    input logic clk,               // 50MHz system clock & active low reset
    input logic rst_n,             // Active low reset
    input logic vld,               // High when inertial sensor reading (pitch) is ready
    input logic [15:0] ptch,       // Pitch of Segway from inertial_intf
    input logic [15:0] ptch_rt,    // Pitch rate (degrees/sec) for D_term of PID
    input logic pwr_up,            // Segway balance control powered up
    input logic rider_off,         // Asserted when no rider detected
    input logic [11:0] steer_pot,  // From A2D_intf (converted from steering potentiometer)
    input logic en_steer,          // Enables steering control
    output logic [11:0] lft_spd,   // 12-bit signed speed of left motor
    output logic [11:0] rght_spd,  // 12-bit signed speed of right motor
    output logic too_fast         // Rider approaching point of minimal control margin
);
    // Module's internal logic for balance control here
    // This may involve PID control and other algorithms based on the inputs.
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic signed [11:0] PID_cntrl_pipe;
    logic [7:0] ss_tmr_pipe;
    logic pwr_up_pipe;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            PID_cntrl_pipe <= 12'sd0;
            ss_tmr_pipe <= 8'h00;
            pwr_up_pipe <= 1'b0;
        end else begin
            pwr_up_pipe <= pwr_up;
            PID_cntrl_pipe <= PID_cntrl;
            ss_tmr_pipe <= ss_tmr;
        end
    end
    
    PID #(fast_sim) pid(
                        .clk(clk),
                        .rst_n(rst_n),
                        .vld(vld),
                        .pwr_up(pwr_up),
                        .rider_off(rider_off),
                        .ptch(ptch),
                        .ptch_rt(ptch_rt),
                        .PID_cntrl(PID_cntrl),//output
                        .ss_tmr(ss_tmr)//output
                    );
    
    SegwayMath segMath(
            .PID_cntrl(PID_cntrl_pipe),
            .ss_tmr(ss_tmr_pipe),
            .steer_pot(steer_pot),
            .en_steer(en_steer),
            .pwr_up(pwr_up_pipe),
            .lft_spd(lft_spd), //output
            .rght_spd(rght_spd),//output
            .too_fast(too_fast)//output
    );
endmodule
