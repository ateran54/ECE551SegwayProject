module piezo_drv_tb();

// Testbench signals
reg clk;
reg rst_n;
reg en_steer;
reg too_fast;
reg batt_low;
wire piezo;
wire piezo_n;

// Clock generation - 50MHz clock (20ns period)
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

// Instantiate the piezo_drv module directly
piezo_drv #(.fast_sim(1)) iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .en_steer(en_steer),
    .too_fast(too_fast),
    .batt_low(batt_low),
    .piezo(piezo),
    .piezo_n(piezo_n)
);

// Static variables for monitoring
logic prev_repeat_done = 0;
logic prev_piezo = 0;

// Test stimulus
initial begin
    // Initialize all inputs
    rst_n = 1;
    en_steer = 0;
    too_fast = 0;
    batt_low = 0;
    
    // Verify no piezo activity before any inputs asserted
    #200;
    $display("=== Initial State Check ===");
    $display("Time: %0t - piezo: %b, piezo_n: %b (should be 0,1)", $time, piezo, piezo_n);
    
    // Apply reset
    $display("\n=== Applying Reset ===");
    rst_n = 0;
    #100;
    rst_n = 1;
    #100;
    $display("Time: %0t - Reset complete, piezo: %b, piezo_n: %b", $time, piezo, piezo_n);
    
    // Test 1: Normal charge fanfare with en_steer
    $display("\n=== Test 1: Normal Charge Fanfare (en_steer) ===");
    en_steer = 1;
    $display("Time: %0t - en_steer asserted", $time);
    
    // Let first sequence complete
    #5000;
    $display("Time: %0t - After first sequence, repeat_done: %b, start_tmr: %b", 
             $time, iDUT.repeat_done, iDUT.start_tmr);
    
    // Wait for timer and second sequence (3 seconds / 64 = 2,343,750 cycles)
    // Adding extra time for sequence completion
    #2000000;  // Wait for 3-second timer in fast sim mode (2.5M cycles)
    $display("Time: %0t - After timer wait, repeat_done: %b, start_tmr: %b", 
             $time, iDUT.repeat_done, iDUT.start_tmr);
    
    // Wait for second sequence
    #10000;
    $display("Time: %0t - Second sequence should have played", $time);
    
    en_steer = 0;
    #1000;
    
    // Test 2: too_fast mode
    $display("\n=== Test 2: too_fast Mode ===");
    too_fast = 1;
    $display("Time: %0t - too_fast asserted", $time);
    #300000;  // Should see continuous first 3 notes
    too_fast = 0;
    $display("Time: %0t - too_fast deasserted", $time);
    #1000;
    
    // Test 3: batt_low backwards play
    $display("\n=== Test 3: batt_low Backwards Play ===");
    batt_low = 1;
    $display("Time: %0t - batt_low asserted", $time);
    #2000000;  // Let backwards sequence complete
    batt_low = 0;
    $display("Time: %0t - batt_low deasserted", $time);
    #1000;
    
    #1000;
    $display("\n=== Test Complete ===");
    $finish;
end

// Monitor state changes
always @(posedge clk) begin
    if (iDUT.current_state != iDUT.next_state) begin
        $display("Time: %0t - State: %s -> %s", 
                 $time, 
                 iDUT.current_state.name(), 
                 iDUT.next_state.name());
    end
end

// Monitor note completions
always @(posedge clk) begin
    if (iDUT.note_done) begin
        $display("Time: %0t - Note done in state: %s", 
                 $time, 
                 iDUT.current_state.name());
    end
end

// Monitor timer events
always @(posedge clk) begin
    // Timer start
    if (iDUT.start_tmr && iDUT.repeat_counter == 64) begin // First increment in fast sim
        $display("Time: %0t - 3-second timer started", $time);
    end
    
    // Timer completion
    if (iDUT.repeat_done && !prev_repeat_done) begin
        $display("Time: %0t - 3-second timer completed", $time);
    end
    prev_repeat_done = iDUT.repeat_done;
end

// Monitor piezo output
always @(posedge clk) begin
    if (piezo != prev_piezo && (en_steer || too_fast || batt_low)) begin
        $display("Time: %0t - Piezo toggled to: %b", $time, piezo);
    end
    prev_piezo = piezo;
end

// Continuous monitoring of key signals
always @(posedge clk) begin
    if ($time % 1000000 == 0 && $time > 0) begin // Every 1M time units
        $display("Time: %0t - Status: state=%s, repeat_done=%b, start_tmr=%b, counter=%0d", 
                 $time, iDUT.current_state.name(), iDUT.repeat_done, iDUT.start_tmr, iDUT.repeat_counter);
    end
end

// Safety timeout
initial begin
    #100000000;  // Increased timeout to accommodate 3-second timer
    $display("ERROR: Testbench timeout!");
    $finish;
end

endmodule