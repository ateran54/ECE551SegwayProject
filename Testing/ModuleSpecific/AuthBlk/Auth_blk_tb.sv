module Auth_blk_tb();

    // Clock and reset
    logic clk;
    logic rst_n;
    
    // DUT inputs
    logic RX;
    logic rider_off;
    
    // DUT outputs
    logic pwr_up;
    
    // UART transmitter for test stimulus
    logic trmt;
    logic [7:0] tx_data;
    logic TX;
    logic tx_done;
    
    // Test constants
    localparam logic [7:0] AUTH_CODE_GO   = 8'h47; // 'G'
    localparam logic [7:0] AUTH_CODE_STOP = 8'h53; // 'S'
    localparam logic [7:0] INVALID_CODE   = 8'h42; // 'B' - invalid
    
    // Clock generation - 50MHz
    always #10ns clk = ~clk;
    
    // DUT instantiation
    Auth_blk dut (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .rider_off(rider_off),
        .pwr_up(pwr_up)
    );
    
    // UART transmitter for sending test data
    UART_tx uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .tx_data(tx_data),
        .TX(TX),
        .tx_done(tx_done)
    );
    
    // Connect TX to RX
    assign RX = TX;
    
    // Task to check test result and print PASS/FAIL (also print DUT state)
    task check_test(input string test_name, input bit condition, input string msg);
        if (condition)
            $display("Time=%0t: PASS - %s (%s) [dut_state=0x%0h]", $time, test_name, msg, dut.current_state);
        else
            $display("Time=%0t: FAIL - %s (%s) [dut_state=0x%0h]", $time, test_name, msg, dut.current_state);
    endtask

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        rider_off = 1;  // Start with no rider
        trmt = 0;
        tx_data = 8'h00;
        
        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(3) @(posedge clk);
        
        $display("=== Auth_blk Testbench Started ===");
        $display("Time=%0t: Reset completed", $time);
        
        // Test 1: Initial state check
        $display("\n--- Test 1: Initial State Check ---");
        check_test("Initial state correct", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));

        // Test 2: Send invalid code while powered down
        $display("\n--- Test 2: Invalid Code While Powered Down ---");
        send_uart_byte(INVALID_CODE);
        repeat(10) @(posedge clk);
        check_test("Invalid code ignored", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));

        // Test 3: Send 'G' to power up
        $display("\n--- Test 3: Power Up with 'G' ---");
        send_uart_byte(AUTH_CODE_GO);
        repeat(10) @(posedge clk);
        check_test("Powered up successfully", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Test 4: Send another 'G' while powered up (should stay powered)
        $display("\n--- Test 4: Send 'G' While Already Powered Up ---");
        send_uart_byte(AUTH_CODE_GO);
        repeat(10) @(posedge clk);
        check_test("Remained powered up", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Test 5: Send invalid code while powered up (should ignore)
        $display("\n--- Test 5: Invalid Code While Powered Up ---");
        send_uart_byte(INVALID_CODE);
        repeat(10) @(posedge clk);
        check_test("Invalid code ignored while powered", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Test 6: Send 'S' while rider is still on (should enter STOP_PENDING)
        $display("\n--- Test 6: Send 'S' While Rider On ---");
        rider_off = 0;  // Rider is on the platform
        repeat(5) @(posedge clk);
        send_uart_byte(AUTH_CODE_STOP);
        repeat(10) @(posedge clk);
        check_test("Stop pending while rider on", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Test 7: Send 'G' while in STOP_PENDING (should cancel shutdown)
        $display("\n--- Test 7: Cancel Shutdown with 'G' ---");
        send_uart_byte(AUTH_CODE_GO);
        repeat(10) @(posedge clk);
        check_test("Shutdown cancelled", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Test 8: Send 'S' then rider gets off (should power down)
        $display("\n--- Test 8: Power Down After Rider Gets Off ---");
        send_uart_byte(AUTH_CODE_STOP);
        repeat(5) @(posedge clk);
        rider_off = 1;  // Rider gets off
        repeat(10) @(posedge clk);
        check_test("Powered down after rider off", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));

        // Test 9: Send 'S' while powered down (should stay down)
        $display("\n--- Test 9: Send 'S' While Already Powered Down ---");
        send_uart_byte(AUTH_CODE_STOP);
        repeat(10) @(posedge clk);
        check_test("Remained powered down", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));

        // Test 10: Complex scenario - Power up, rider gets on, stop request, rider stays, another stop, rider gets off
        $display("\n--- Test 10: Complex Scenario ---");
        // Power up
        send_uart_byte(AUTH_CODE_GO);
        repeat(10) @(posedge clk);

        // Rider gets on
        rider_off = 0;
        repeat(5) @(posedge clk);

        // First stop request
        send_uart_byte(AUTH_CODE_STOP);
        repeat(10) @(posedge clk);
        check_test("Should stay powered with rider on", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Second stop request (still in STOP_PENDING)
        send_uart_byte(AUTH_CODE_STOP);
        repeat(10) @(posedge clk);
        check_test("Should stay powered with rider on", pwr_up == 1, $sformatf("pwr_up=%b", pwr_up));

        // Rider gets off
        rider_off = 1;
        repeat(10) @(posedge clk);
        check_test("Should power down when rider gets off", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));
        $display("Time=%0t: PASS - Complex scenario completed (pwr_up=%b)", $time, pwr_up);

        // Test 11: Immediate power down (rider already off when 'S' received)
        $display("\n--- Test 11: Immediate Power Down ---");
        rider_off = 1;  // Ensure rider is off
        send_uart_byte(AUTH_CODE_GO);  // Power up first
        repeat(10) @(posedge clk);

        send_uart_byte(AUTH_CODE_STOP);  // Send stop with rider already off
        repeat(10) @(posedge clk);
        check_test("Should power down immediately when rider is off", pwr_up == 0, $sformatf("pwr_up=%b", pwr_up));

        $display("\n=== All Tests Completed Successfully ===");
        $stop;
    end
    
    // Task to send a UART byte
    task send_uart_byte(input [7:0] data);
        begin
            $display("Time=%0t: Sending UART byte: 0x%02h ('%c')", $time, data, data);
            tx_data = data;
            trmt = 1;
            @(posedge clk);
            #1;
            trmt = 0;
    
            wait(tx_done == 1);
            repeat(50) @(posedge clk);  // Allow some settling time
        end
    endtask
    

    // Timeout watchdog
    initial begin
        #50ms;
        $error("Testbench timeout!");
        $stop;
    end

endmodule