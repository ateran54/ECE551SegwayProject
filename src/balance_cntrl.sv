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
    reg [7:0] ss_tmr;

    PID #(fast_sim) pid(
                        .clk(clk),
                        .rst_n(rst_n),
                        .vld(vld),
                        .pwr_up(pwr_up),
                        .rider_off(rider_off),
                        .ptch(ptch),
                        .ptch_rt(ptch_rt),
                        .PID_cntrl(PID_cntrl),
                        .ss_tmr(ss_tmr)
                    );
    
    //pipeline all inputs to SegwayMath
    // logic signed [11:0] PID_cntrl_pipelined;
    // logic [7:0] ss_tmr_pipelined;
    // logic [11:0] steer_pot_pipelined;
    // logic en_steer_pipelined;
    // logic pwr_up_pipelined;
    
    // always_ff @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         PID_cntrl_pipelined <= '0;
    //         ss_tmr_pipelined <= '0;
    //         steer_pot_pipelined <= '0;
    //         en_steer_pipelined <= '0;
    //         pwr_up_pipelined <= '0;
    //     end else begin
    //         PID_cntrl_pipelined <= PID_cntrl;
    //         ss_tmr_pipelined <= ss_tmr;
    //         steer_pot_pipelined <= steer_pot;
    //         en_steer_pipelined <= en_steer;
    //         pwr_up_pipelined <= pwr_up;
    //     end
    // end

    SegwayMath segMath(
            .clk(clk),
            .rst_n(rst_n),
            .PID_cntrl(PID_cntrl),
            .ss_tmr(ss_tmr),
            .steer_pot(steer_pot),
            .en_steer(en_steer),
            .pwr_up(pwr_up),
            .lft_spd(lft_spd),
            .rght_spd(rght_spd),
            .too_fast(too_fast)
    );
endmodule
