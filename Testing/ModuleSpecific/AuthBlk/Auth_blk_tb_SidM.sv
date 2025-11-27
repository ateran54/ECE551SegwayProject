`timescale 1ns/1ps

module Auth_blk_tb_SidM;

    // ------------------------------
    // DUT Interface Signals
    // ------------------------------
    logic clk;
    logic rst_n;
    logic trmt;
    logic [7:0] tx_data;
    logic TX;
    logic tx_done;
    logic [7:0] rx_data;
    logic rider_off;
    logic pwr_up;

    // ------------------------------
    // Clock Generation (50 MHz)
    // ------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    // ------------------------------
    // Instantiate Modules
    // ------------------------------
    uart_tx transmitter(
        .clk(clk), 
        .rst_n(rst_n),
        .trmt(trmt),
        .tx_data(tx_data),
        .TX(TX),
        .tx_done(tx_done)
    );
    
    Auth_blk authorization(
        .clk(clk),
        .rst_n(rst_n),
        .RX(TX),
        .rider_off(rider_off),
        .pwr_up(pwr_up)
    );

    // ======================================================
    //                      TASKS
    // ======================================================

    // --- Reset task ---
    task automatic reset_dut();
        $display("\n--- Resetting DUT ---");
        rst_n = 0;
        trmt = 0;
        tx_data = '0;
    rider_off = 0;
        @(posedge clk);
        #100;
        rst_n = 1;
        @(posedge clk);
        #1;
    $display("Reset complete. Expecting IDLE state...");
    check_state(1'b0);
    endtask

    // --- UART send helper task ---
    task automatic send_uart_byte(input [7:0] data);
        $display("\nTransmitting UART byte: 0x%0h", data);
        tx_data = data;
        trmt = 1;
        @(posedge clk);
        #1;
        trmt = 0;
        wait(tx_done);
        @(posedge clk);
        @(posedge clk);
    endtask

    // --- State check helper task ---
    task automatic check_state(
        input logic expected_pwr_up
    );
        if (pwr_up !== expected_pwr_up) begin
            $display("❌ pwr_up mismatch: expected %0b, got %0b", expected_pwr_up, pwr_up);
            $stop;
        end

    $display("✅ PASS: pwr_up=%0b, state=%0d as expected", pwr_up, authorization.current_state);
    endtask

    // --- Combined UART + Check task ---
    task automatic send_and_check(
        input [7:0] data,
        input logic expected_pwr_up
    );
        send_uart_byte(data);
        check_state(expected_pwr_up);
    endtask

    // ======================================================
    //                   MAIN TEST SEQUENCE
    // ======================================================
    initial begin
        $display("=== Starting Auth_blk Testbench ===");
        reset_dut();

        // 1️⃣ Transition to PWR_UP
        send_and_check(8'h47, 1'b1);

        // 2️⃣ Transition to BLUE_DISCON
        send_and_check(8'h53, 1'b1);

        // 3️⃣ Rider turns off → IDLE
        $display("\nSetting rider_off = 1 to return to IDLE...");
        rider_off = 1;
        @(posedge clk);
        check_state(1'b0);

        // 4️⃣ Rider back on, transition to PWR_UP again
        rider_off = 0;
        send_and_check(8'h47, 1'b1);

        // 5️⃣ Transition back to IDLE (simulate disconnect)
        send_and_check(8'h53, 1'b0);

        // 6️⃣ Repeat power-up + blue-disconnect again for robustness
        send_and_check(8'h47, 1'b1);
        send_and_check(8'h53, 1'b1);
        send_and_check(8'h47, 1'b1);

        $display("\n🎉 YAHOO! All tests passed successfully!");
        $stop;
    end

endmodule
