module PID_Math_tb;

    // DUT signals
    logic signed [15:0] ptch;
    logic signed [15:0] ptch_rt;
    logic signed [17:0] integrator;
    logic [11:0] PID_cntrl_dut, PID_cntrl_ref;
    integer i, j;
    logic signed [15:0] ptch_start, ptch_rt_start;
    logic signed [17:0] integrator_start;

    // Instantiate DUT
    PID_Math dut (
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .integrator(integrator),
        .PID_cntrl(PID_cntrl_dut)
    );

    // Instantiate reference model (identical logic, separate instance)
    PID_Math refere (
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .integrator(integrator),
        .PID_cntrl(PID_cntrl_ref)
    );

    initial begin
        // Test 1: All zeros
        ptch = 16'sd0; ptch_rt = 16'sd0; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: All zeros | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: All zeros | DUT: %h", PID_cntrl_dut);

        // Test 2: Max positive ptch (no sat)
        ptch = 16'sd511; ptch_rt = 16'sd0; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Max positive ptch | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Max positive ptch | DUT: %h", PID_cntrl_dut);

        // Test 3: Just above max ptch (saturate)
        ptch = 16'sd512; ptch_rt = 16'sd0; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Above max ptch | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Above max ptch | DUT: %h", PID_cntrl_dut);

        // Test 4: Min negative ptch (no sat)
        ptch = -16'sd512; ptch_rt = 16'sd0; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Min negative ptch | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Min negative ptch | DUT: %h", PID_cntrl_dut);

        // Test 5: Below min ptch (saturate)
        ptch = -16'sd513; ptch_rt = 16'sd0; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Below min ptch | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Below min ptch | DUT: %h", PID_cntrl_dut);

        // Test 6: Positive ptch_rt
        ptch = 16'sd0; ptch_rt = 16'sd64; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Positive ptch_rt | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Positive ptch_rt | DUT: %h", PID_cntrl_dut);

        // Test 7: Negative ptch_rt
        ptch = 16'sd0; ptch_rt = -16'sd64; integrator = 18'sd0; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Negative ptch_rt | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Negative ptch_rt | DUT: %h", PID_cntrl_dut);

        // Test 8: Large positive integrator
        ptch = 16'sd0; ptch_rt = 16'sd0; integrator = 18'sd65536; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Large positive integrator | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Large positive integrator | DUT: %h", PID_cntrl_dut);

        // Test 9: Large negative integrator
        ptch = 16'sd0; ptch_rt = 16'sd0; integrator = -18'sd65536; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Large negative integrator | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Large negative integrator | DUT: %h", PID_cntrl_dut);

        // Test 10: Mixed values
        ptch = 16'sd100; ptch_rt = 16'sd20; integrator = 18'sd5000; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Mixed values | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Mixed values | DUT: %h", PID_cntrl_dut);

        // Test 11: Mixed values 2
        ptch = 16'sd400; ptch_rt = -16'sd100; integrator = 18'sd20000; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Mixed values 2 | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Mixed values 2 | DUT: %h", PID_cntrl_dut);

        // Test 12: Mixed values 3
        ptch = -16'sd400; ptch_rt = 16'sd100; integrator = -18'sd20000; #1;
        if (PID_cntrl_dut !== PID_cntrl_ref)
            $display("FAIL: Mixed values 3 | DUT: %h, REF: %h", PID_cntrl_dut, PID_cntrl_ref);
        else
            $display("PASS: Mixed values 3 | DUT: %h", PID_cntrl_dut);

         
        ptch = 16'hFF00; // -256
        integrator = 18'h3C000; // 245760
        ptch_rt = 16'h0FFF; // 4095

        $display("Starting ramping stimulus...");

        // 8 repeat loops, 64 iterations each
        for (j = 0; j < 8; j = j + 1) begin
            for (i = 0; i < 64; i = i + 1) begin
                #1;
                // Print a few samples for waveform shape check
                if ((i == 0) || (i == 32) || (i == 63))
                    $display("Ramp j=%0d i=%0d | ptch=%0d ptch_rt=%0d integrator=%0d | DUT=%h REF=%h",
                        j, i, ptch, ptch_rt, integrator, PID_cntrl_dut, PID_cntrl_ref);

                // Check for mismatch
                if (PID_cntrl_dut !== PID_cntrl_ref)
                    $display("FAIL: Ramp j=%0d i=%0d | DUT: %h, REF: %h", j, i, PID_cntrl_dut, PID_cntrl_ref);

                // ptch always increases by 1
                ptch = ptch + 1;

                // integrator ramps up for first 2 loops, down for next 2, up for next 2, down for last 2
                if (j < 2)
                    integrator = integrator + 18'h00080;
                else if (j < 4)
                    integrator = integrator - 18'h00080;
                else if (j < 6)
                    integrator = integrator + 18'h00080;
                else
                    integrator = integrator - 18'h00080;

                // ptch_rt ramps down for even loops, up for odd loops
                if (j % 2 == 0)
                    ptch_rt = ptch_rt - 16'h0100;
                else
                    ptch_rt = ptch_rt + 16'h0100;
            end
        end

        $display("Testbench completed.");
        $stop;
    end

endmodule