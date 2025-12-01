module piezo_tb();

// Testbench signals
reg clk;
reg RST_n;
reg en_steer;
reg too_fast;
reg batt_low;
wire piezo;
wire piezo_n;
wire [7:0] LED;

// Clock generation - 50MHz clock (20ns period)
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

// Instantiate the piezoTest module (DUT)
piezoTest iDUT(
    .clk(clk),
    .RST_n(RST_n),
    .en_steer(en_steer),
    .too_fast(too_fast),
    .batt_low(batt_low),
    .piezo(piezo),
    .piezo_n(piezo_n),
    .LED(LED)
);

// Test stimulus
initial begin
    // Initialize all inputs
    RST_n = 0;
    en_steer = 0;
    too_fast = 0;
    batt_low = 0;
    
    // Apply reset
    #100;
    RST_n = 1;
    #100;
    
    $display("=== Starting Piezo Driver Testbench ===");
    $display("Time: %0t - Reset released", $time);
    
    // Test 1: Normal charge fanfare with en_steer
    $display("\n=== Test 1: Normal Charge Fanfare ===");
    en_steer = 1;
    #1000;  // Let it play for a while
    // Don't turn off en_steer here - let it continue for timer testing
    #2000;  // Wait and observe
    
    // Test 2: Wait for 3-second repeat timer
    $display("\n=== Test 2: Waiting for 3-second repeat ===");
    en_steer = 1;
    #10000;  // Wait to see the fanfare sequence and timer behavior
    $display("Time: %0t - repeat_counter: %0d, repeat_done: %b, start_tmr: %b", 
             $time, iDUT.iDUT.repeat_counter, iDUT.iDUT.repeat_done, iDUT.iDUT.start_tmr);
    #200000;  // Wait much longer to see if repeat_done gets set (increased from 100000)
    $display("Time: %0t - repeat_counter: %0d, repeat_done: %b, start_tmr: %b", 
             $time, iDUT.iDUT.repeat_counter, iDUT.iDUT.repeat_done, iDUT.iDUT.start_tmr);
    en_steer = 0;
    
    // Test 3: too_fast priority test
    $display("\n=== Test 3: too_fast Priority Test ===");
    en_steer = 1;
    #500;
    too_fast = 1;  // Should interrupt and play first 3 notes continuously
    #2000;
    too_fast = 0;
    #1000;
    en_steer = 0;
    
    // Test 4: batt_low backwards play
    $display("\n=== Test 4: batt_low Backwards Play ===");
    batt_low = 1;
    #2000;  // Should play charge fanfare backwards
    batt_low = 0;
    #500;
    
    // Test 5: Multiple priority conditions
    $display("\n=== Test 5: Multiple Priority Conditions ===");
    en_steer = 1;
    #300;
    batt_low = 1;
    #300;
    too_fast = 1;  // too_fast should have highest priority
    #1000;
    too_fast = 0;
    #500;
    batt_low = 0;
    #500;
    en_steer = 0;
    
    // Test 6: Reset during operation
    $display("\n=== Test 6: Reset During Operation ===");
    en_steer = 1;
    #500;
    RST_n = 0;
    #100;
    RST_n = 1;
    #500;
    en_steer = 0;
    
    // Test 7: Rapid input changes
    $display("\n=== Test 7: Rapid Input Changes ===");
    repeat(5) begin
        en_steer = 1;
        #200;
        en_steer = 0;
        #200;
    end
    
    #1000;
    $display("\n=== Testbench Complete ===");
    $stop;
end

// Monitor important signals
always @(posedge clk) begin
    // Monitor state changes
    if (iDUT.iDUT.current_state != iDUT.iDUT.next_state) begin
        $display("Time: %0t - State change: %s -> %s", 
                 $time, 
                 iDUT.iDUT.current_state.name(), 
                 iDUT.iDUT.next_state.name());
    end
    
    // Monitor when notes complete
    if (iDUT.iDUT.note_done) begin
        $display("Time: %0t - Note completed in state: %s", 
                 $time, 
                 iDUT.iDUT.current_state.name());
    end
    
    // Monitor repeat timer completion
    if (iDUT.iDUT.repeat_done) begin
        $display("Time: %0t - 3-second repeat timer completed", $time);
    end
    
    // Monitor timer start
    if (iDUT.iDUT.start_tmr && iDUT.iDUT.repeat_counter == 1) begin
        $display("Time: %0t - Repeat timer started", $time);
    end
    
    // Monitor timer progress periodically  
    if (iDUT.iDUT.start_tmr && (iDUT.iDUT.repeat_counter % 100000 == 0) && iDUT.iDUT.repeat_counter > 0) begin
        $display("Time: %0t - Timer progress: %0d", $time, iDUT.iDUT.repeat_counter);
    end
    
    // Monitor when timer reaches target value (depends on fast_sim parameter)
    if (iDUT.iDUT.start_tmr && iDUT.iDUT.repeat_counter >= (iDUT.iDUT.THREE_SEC / (iDUT.iDUT.fast_sim ? 64 : 1)) - 1) begin
        $display("Time: %0t - Timer reached target value: %0d", $time, iDUT.iDUT.repeat_counter);
    end
end

// Monitor piezo output changes
always @(posedge clk) begin
    static logic prev_piezo = 0;
    if (piezo != prev_piezo) begin
        $display("Time: %0t - Piezo output changed to: %b", $time, piezo);
        prev_piezo = piezo;
    end
end

// Timeout watchdog
initial begin
    #200000000;  // Increased timeout for timer testing
    $display("ERROR: Testbench timeout!");
    $stop;
end

endmodule