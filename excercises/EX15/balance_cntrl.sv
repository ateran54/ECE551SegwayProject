module balance_cntrl
#(parameter fast_sim = 1)
(
    input  logic           clk,       // 50 MHz system clock
    input  logic           rst_n,     // active low reset
    input  logic           vld,       // high when new inertial sensor reading (ptch) is ready
    input  logic signed [15:0] ptch,   // pitch from inertial_intf
    input  logic signed [15:0] ptch_rt,// pitch rate (degrees/sec) for D term
    input  logic           pwr_up,    // asserted when balance control powered up
    input  logic           rider_off, // asserted when no rider detected (clears integrator)
    input  logic [11:0]    steer_pot, // from A2D_intf
    input  logic           en_steer,  // enables steering control

    output logic signed [11:0] lft_spd, // left motor signed 12-bit speed
    output logic signed [11:0] rght_spd,// right motor signed 12-bit speed
    output logic               too_fast // rider approaching minimal control margin
);

    // Expose PID outputs from the PID instance
    logic signed [11:0] PID_cntrl;
    logic [7:0]        ss_tmr;   
    // Instantiate PID
    PID #(.fast_sim(fast_sim)) u_pid (
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

    SegwayMath u_math (
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
