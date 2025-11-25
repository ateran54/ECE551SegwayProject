`timescale 1ns/1ps

module steer_en_tb;

    //------------------------------------------------------------------
    // Load cell thresholds from DUT
    //------------------------------------------------------------------
    localparam MIN_RIDER_WT   = 12'h200; // 512
    localparam WT_HYSTERESIS  = 8'h40;   // 64
    localparam MIN_RIDER_ON   = MIN_RIDER_WT;               // 512
    localparam MIN_RIDER_OFF  = MIN_RIDER_WT - WT_HYSTERESIS; // 448

    //------------------------------------------------------------------
    // DUT I/O
    //------------------------------------------------------------------
    logic clk;
    logic rst_n;
    logic [11:0] lft_ld;
    logic [11:0] rght_ld;

    logic en_steer;
    logic rider_off;

    //------------------------------------------------------------------
    // Instantiate DUT
    //------------------------------------------------------------------
    steer_en #(.fast_sim(1)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .lft_ld(lft_ld),
        .rght_ld(rght_ld),
        .en_steer(en_steer),
        .rider_off(rider_off)
    );

    //------------------------------------------------------------------
    // Clock
    //------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz
    end

    //------------------------------------------------------------------
    // Reset
    //------------------------------------------------------------------
    task apply_reset();
        begin
            rst_n = 0;
            lft_ld = 0;
            rght_ld = 0;
            repeat (10) @(posedge clk);
            rst_n = 1;
            repeat (5) @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------
    // Drive loads
    //------------------------------------------------------------------
    task set_loads(input int L, input int R);
        begin
            lft_ld  = L;
            rght_ld = R;
            @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------
    // TEST SEQUENCES
    //------------------------------------------------------------------

    task no_rider();
        $display("=== TEST: No rider ===");
        set_loads(0, 0);
        repeat (20) @(posedge clk);
        if (!rider_off)
            $error("FAIL: rider_off should be 1 when no rider");
        if (en_steer)
            $error("FAIL: en_steer must be 0 with no rider");
    endtask

    task rider_steps_on();
        $display("=== TEST: Rider steps on ===");

        // Below ON threshold
        set_loads(200, 150); // sum=350 < 512
        repeat (20) @(posedge clk);

        if (!rider_off)
            $error("Expected rider_off=1 just below min weight");

        // Now exceed min weight → sum ~ 600
        set_loads(310, 310); // sum=620 >512
        repeat (20) @(posedge clk);

        if (rider_off)
            $error("FAIL: rider_off must go low after rider steps on");
    endtask

    task balancing_phase();
        $display("=== TEST: Balancing for 1.3s ===");

        // Balanced: very small diff
        set_loads(320, 315);
        begin : block
            fork
                begin
                    wait(en_steer == 1);
                    disable block;
                end

                begin
                    repeat (30000) @(posedge clk);
                    $error("FAIL: steering should be enabled after balance period");
                end
            join
        end
        if (!en_steer)
            $error("FAIL: steering should be enabled after balance period");
    endtask

    task imbalance_small();
        $display("=== TEST: Small imbalance (normal) ===");

        // |600 - 400| = 200, sum = 1000 → 1/4 sum =250 → NOT > threshold
        set_loads(600, 400);
        repeat (30) @(posedge clk);

        if (!en_steer)
            $error("Small imbalance should NOT disable steering");
    endtask

    task imbalance_large();
        $display("=== TEST: Large imbalance (>15/16 diff) ===");

        // diff=690, sum=720 → 15/16 sum=675 → diff>675 triggers exit
        set_loads(700, 20);
        repeat (20) @(posedge clk);

        if (en_steer)
            $error("Large imbalance should EXIT steering mode");
    endtask

    task re_balance();
        $display("=== TEST: Rebalance back into steering ===");

        set_loads(330, 330);
        repeat (200) @(posedge clk);

        if (!en_steer)
            $error("After rebalancing for timer, steering must enable again");
    endtask

    task slow_step_off();
        $display("=== TEST: Slow step-off ===");

        set_loads(300, 30);  // sum=330 <448 → below OFF threshold
        repeat (30) @(posedge clk);

        if (!rider_off)
            $error("FAIL: rider_off should assert during slow step off");

        if (en_steer)
            $error("FAIL: steering must disable when rider stepping off");
    endtask

    task sudden_fall();
        $display("=== TEST: Sudden fall-off ===");

        // back on
        set_loads(320, 330);
        repeat (100) @(posedge clk);

        // balanced → steering ON
        if (!en_steer)
            $error("Setup error: expected en_steer before falling");

        // sudden fall
        set_loads(0, 0);
        repeat (20) @(posedge clk);

        if (!rider_off)
            $error("FAIL: rider_off should assert immediately on fall");

        if (en_steer)
            $error("FAIL: steering must drop on fall");
    endtask

    //------------------------------------------------------------------
    // Master Test Sequence
    //------------------------------------------------------------------
    initial begin
        $display("===== START steer_en FULL LOAD-CELL SIMULATION TEST =====");

        apply_reset();

        no_rider();
        rider_steps_on();
        balancing_phase();
        imbalance_small();
        imbalance_large();
        re_balance();
        slow_step_off();
        sudden_fall();

        $display("===== END OF TEST – steer_en VERIFIED =====");
        #100;
        $stop;
    end

    //------------------------------------------------------------------
    // Waveform dump
    //------------------------------------------------------------------
    initial begin
        $dumpfile("steer_en_tb.vcd");
        $dumpvars(0, steer_en_tb);
    end

endmodule
