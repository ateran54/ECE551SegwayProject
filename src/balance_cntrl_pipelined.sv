module balance_cntrl_pipelined #(parameter fast_sim = 1)(
    input logic clk,               // 50MHz system clock & active low reset
    input logic rst_n,             // Active low reset
    input logic vld,               // High when inertial sensor reading (pitch) is ready (pipelined)
    input logic [15:0] ptch,       // Pitch of Segway from inertial_intf (pipelined)
    input logic [15:0] ptch_rt,    // Pitch rate (degrees/sec) for D_term of PID (pipelined)
    input logic pwr_up,            // Segway balance control powered up (pipelined)
    input logic rider_off,         // Asserted when no rider detected (pipelined)
    input logic [11:0] steer_pot_pipe2,  // From A2D_intf (pipelined stage 2)
    input logic en_steer_pipe2,          // Enables steering control (pipelined stage 2)
    input logic pwr_up_pipe2,            // Power up signal for stage 2 (pipelined)
    input logic signed [11:0] PID_cntrl_pipe2,  // PID control from pipeline stage 2
    input logic [7:0] ss_tmr_pipe2,             // Soft start timer from pipeline stage 2
    output logic signed [11:0] PID_cntrl_stage1, // PID control output from stage 1
    output logic [7:0] ss_tmr_stage1,           // Soft start timer output from stage 1
    output logic [11:0] lft_spd,   // 12-bit signed speed of left motor
    output logic [11:0] rght_spd,  // 12-bit signed speed of right motor
    output logic too_fast         // Rider approaching point of minimal control margin
);

    // PID module computes in pipeline stage 1
    PID #(fast_sim) pid(
                        .clk(clk),
                        .rst_n(rst_n),
                        .vld(vld),
                        .pwr_up(pwr_up),
                        .rider_off(rider_off),
                        .ptch(ptch),
                        .ptch_rt(ptch_rt),
                        .PID_cntrl(PID_cntrl_stage1),
                        .ss_tmr(ss_tmr_stage1)
                    );
    
    // SegwayMath computes in pipeline stage 2 using pipelined inputs
    SegwayMath segMath(
            .PID_cntrl(PID_cntrl_pipe2),  // Use pipelined PID control
            .ss_tmr(ss_tmr_pipe2),        // Use pipelined soft start timer
            .steer_pot(steer_pot_pipe2),  // Use pipelined steering pot
            .en_steer(en_steer_pipe2),    // Use pipelined steering enable
            .pwr_up(pwr_up_pipe2),        // Use pipelined power up
            .lft_spd(lft_spd),
            .rght_spd(rght_spd),
            .too_fast(too_fast)
    );
endmodule