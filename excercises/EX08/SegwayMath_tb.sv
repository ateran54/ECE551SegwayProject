module SegwayMath_tb();
    // DUT signals
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic [11:0] steer_pot;
    logic en_steer;
    logic pwr_up;
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic too_fast;

    // Error tracking
    int error_count = 0;

    // Instantiate DUT
    SegwayMath dut(
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    // Task to check and report errors
    task check_error(string message, logic condition);
        if (condition) begin
            $display("ERROR at time %0t: %s", $time, message);
            error_count++;
        end
    endtask

    initial begin
        $timeformat(-9, 2, " ns", 20);

        // === Test 1: PID and ss_tmr ramping ===
        $display("\n=== Test 1: PID and ss_tmr ramping ===");
        PID_cntrl = 12'h5FF;  // +1535
        ss_tmr = 8'h00;
        steer_pot = 12'h800;  // Middle
        en_steer = 1'b0;
        pwr_up = 1'b1;

        // Ramp up ss_tmr
        $display("Ramping up ss_tmr from 0 to 0xFF");
        for (int i = 0; i <= 255; i++) begin
            ss_tmr = i[7:0];
            #10;
            if (i % 32 == 0) begin
                $display("ss_tmr=%h, lft_spd=%h, rght_spd=%h, too_fast=%b", 
                    ss_tmr, lft_spd, rght_spd, too_fast);
            end
            // Check for speed limit
            check_error("too_fast not asserted when speed exceeds 1536",
                (lft_spd > 12'sd1536 || rght_spd > 12'sd1536) && !too_fast);
        end

        // Ramp PID_cntrl from 0x5FF to 0xE00
        $display("\nRamping PID_cntrl from 0x5FF to 0xE00");
        for (int i = 12'h5FF; i >= 12'hE00; i -= 32) begin
            PID_cntrl = i[11:0];
            #10;
            $display("PID_cntrl=%h, lft_spd=%h, rght_spd=%h, too_fast=%b", 
                PID_cntrl, lft_spd, rght_spd, too_fast);
            // Check for speed limit
            check_error("too_fast not asserted when speed exceeds 1536",
                (lft_spd > 12'sd1536 || rght_spd > 12'sd1536) && !too_fast);
        end

        // === Test 2: Steering sweep and power down ===
        $display("\n=== Test 2: Steering sweep and power down ===");
        PID_cntrl = 12'h3FF;    // 1023
        ss_tmr = 8'hFF;         // Full scale
        steer_pot = 12'h000;    // Start at 0
        en_steer = 1'b1;        // Enable steering
        pwr_up = 1'b1;

        for (int i = 0; i < 64; i++) begin
            PID_cntrl = 12'h3FF - (i * 32);
            steer_pot = i * 12'h40;
            #10;
            if (i % 8 == 0) begin
                $display("Time=%0t: PID=%h, steer_pot=%h, lft_spd=%h, rght_spd=%h, too_fast=%b", 
                    $time, PID_cntrl, steer_pot, lft_spd, rght_spd, too_fast);
            end
            // Check steer_pot limiting
            if (steer_pot < 12'h200 || steer_pot > 12'hE00) begin
                check_error("steer_pot out of range but speeds differ",
                    lft_spd != rght_spd);
            end
            // Check for speed limit
            check_error("too_fast not asserted when speed exceeds 1536",
                (lft_spd > 12'sd1536 || rght_spd > 12'sd1536) && !too_fast);
        end

        // Power down at the end
        $display("\nPower down test");
        pwr_up = 1'b0;
        #10;
        $display("After power down: lft_spd=%h, rght_spd=%h", lft_spd, rght_spd);
        check_error("lft_spd not zero after power down", lft_spd !== 12'sd0);
        check_error("rght_spd not zero after power down", rght_spd !== 12'sd0);

        // Final test report
        $display("\n=== Test Summary ===");
        if (error_count > 0) begin
            $display("SIMULATION FAILED with %0d errors", error_count);
        end else begin
            $display("SIMULATION PASSED - All tests completed successfully");
        end

        $stop();
    end

    // Monitor for steering differential
    always @(lft_spd, rght_spd) begin
        if (en_steer && (lft_spd != rght_spd)) begin
            $display("Time=%0t: Steering differential: lft=%h, rght=%h, diff=%0d", 
                $time, lft_spd, rght_spd, $signed(lft_spd) - $signed(rght_spd));
        end
    end

    // Monitor for too_fast condition
    always @(too_fast) begin
        if (too_fast) begin
            $display("Time=%0t: WARNING: Speed limit exceeded (too_fast=1)", $time);
        end
    end

endmodule