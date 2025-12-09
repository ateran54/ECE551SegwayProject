module SegwayMath_tb;

    // Inputs
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic [11:0] steer_pot;
    logic en_steer;
    logic pwr_up;

    // Outputs
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic too_fast;

    // Instantiate the UUT
    SegwayMath uut (
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    initial begin
        // Default values
        PID_cntrl = 12'h5FF;     // +1535
        ss_tmr = 8'h00;
        steer_pot = 12'h7FF;
        en_steer = 0;
        pwr_up = 1;

        // First phase: ramp ss_tmr from 0 to 255 while PID_cntrl stays at 1535
        repeat (255) begin
            #1;
            ss_tmr += 1'h1;
        end

        // Second phase: hold ss_tmr at 255, ramp PID_cntrl from 1535 to -512
        repeat (2048) begin
            #1;
            PID_cntrl -= 1'h1;
        end

        #100;
        $stop;
    end
endmodule

module SegwayMath_steering_tb;

    // Inputs
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic [11:0] steer_pot;
    logic en_steer;
    logic pwr_up;

    // Outputs
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic too_fast;

    // Instantiate the Unit Under Test (UUT)
    SegwayMath uut (
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    initial begin
        // Initial values
        PID_cntrl = 12'sh3FF;     //  1023
        ss_tmr    = 8'hFF;        //  constant throughout
        steer_pot = 12'h000;      //  0
        en_steer  = 1;            //  always enabled
        pwr_up    = 1;            //  stays 1 until end

        // // Run from PID = +1023 to -1024 = 2048 steer

        repeat (2048) begin
            #5; // Time step
            if (PID_cntrl != 12'shC00)
                PID_cntrl -= 1;           // Down by 1 each step
            if (steer_pot < 12'hFFF - 1)
                steer_pot += 2;           // Up by 2 each step (0 → 0xFFE in 2047 steps)
            else
                steer_pot = 12'hFFE;
        end

        // Drop power after the full loop
        #50;
        pwr_up = 0;

        // Finish simulation
        #5000;
        $stop;
    end

endmodule