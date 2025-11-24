module tb_SPI_inert_mnrch;

    // DUT <-> Sensor interface
    logic clk;
    logic rst_n;
    logic wrt;
    logic [15:0] wrt_data;
    logic done;
    logic [15:0] rd_data;
    logic SS_n, SCLK, MOSI, MISO;
    logic INT;              // from NEMO sensor
    logic nemo_setup;       // from NEMO sensor (internal config flag)

    // Instantiate DUT (SPI Monarch)
    SPI_mnrch dut (
        .clk(clk),
        .rst_n(rst_n),
        .MISO(MISO),
        .wrt(wrt),
        .wrt_data(wrt_data),
        .done(done),
        .rd_data(rd_data),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI)
    );

    // Instantiate Inertial Sensor (SPI Slave)
    SPI_iNEMO1 nemo (
        .SCLK(SCLK),
        .SS_n(SS_n),
        .MOSI(MOSI),
        .MISO(MISO),
        .INT(INT)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;

    // Reset task
    task automatic reset_dut();
        rst_n = 0;
        wrt = 0;
        wrt_data = '0;
        #200;
        rst_n = 1;
        #100;
    endtask

    // SPI Transaction helper
    task automatic spi_transaction(input logic [15:0] tx_data);
        wrt_data = tx_data;
        wrt = 1;
        @(posedge clk);
        #1;
        wrt = 0;

        begin : spi_transaction_block
            fork 
                begin
                    wait(done == 1'b1);
                    disable spi_transaction_block;
                end

                begin
                    repeat(10000000) @(posedge clk);
                    $display("ERROR: SPI TRANSACTION TIMED OUT! DATA: %h", wrt_data);
                    $stop;
                end
            join
        end
        
        @(posedge clk);
        $display("[%0t] Transaction complete: wt_data=%h | rd_data=%h", $time, tx_data, rd_data);
    endtask

        // SPI Transaction helper
    task automatic wait_for_INT();
        begin : wait_for_int
            fork 
                begin
                    wait(INT);
                    disable wait_for_int;
                end

                begin
                    repeat(10000000) @(posedge clk);
                    $display("ERROR: WAITING FOR INT TIMED OUT!");
                    $stop;
                end
            join
        end
    endtask

    // Test sequence
    initial begin
        $display("=== Starting SPI Monarch Testbench ===");
        reset_dut();

        // --- Test 1: Read WHO_AM_I register ---
        $display("\n[TEST 1] WHO_AM_I Register Read");
        spi_transaction(16'h8F00);  // Read command
        if (rd_data[7:0] == 8'h6A)
            $display("PASS ✅: WHO_AM_I returned 0x6A");
        else
            $display("FAIL ❌: Expected 0x6A, got %h", rd_data[7:0]);

        // --- Test 2: Write INT Config register ---
        $display("\n[TEST 2] Write INT Config (0x0D02)");
        spi_transaction(16'h0D02);
        #2000; // wait for sensor to configure

        // --- Test 3: Wait for INT and Read Low byte of Pitch Register ---
        $display("\n[TEST 3] Wait for INT, then read pitch low (0xA2xx)");
        wait_for_INT();
        $display("[%0t] INT asserted", $time);
        spi_transaction(16'hA200);
        if (rd_data[7:0] == 8'h63)
            $display("PASS ✅: Pitch low read correct value 0x63");
        else
            $display("FAIL ❌: Expected 0x63, got %h", rd_data[7:0]);

        // --- Test 4: Wait for INT and Read High byte of Pitch Register ---
        $display("\n[TEST 4] Wait for INT, then read pitch high (0xA3xx)");
        $display("[%0t] INT asserted", $time);
        spi_transaction(16'hA300);
        if (rd_data[7:0] == 8'h56)
            $display("PASS ✅: Pitch low read correct value 0x56");
        else
            $display("FAIL ❌: Expected 0x56, got %h", rd_data[7:0]);

        wait_for_INT();
        //repeat again for second line
                
        $display("\n[TEST 5] Wait for INT, then read pitch low (0xA2xx)");
        wait_for_INT();
        $display("[%0t] INT asserted", $time);
        spi_transaction(16'hA200);
        if (rd_data[7:0] == 8'h0d)
            $display("PASS ✅: Pitch low read correct value 0x0d");
        else
            $display("FAIL ❌: Expected 0x0d, got %h", rd_data[7:0]);

        $display("\n[TEST 6] Wait for INT, then read pitch high (0xA3xx)");
        $display("[%0t] INT asserted", $time);
        spi_transaction(16'hA300);
        if (rd_data[7:0] == 8'hcd)
            $display("PASS ✅: Pitch low read correct value 0xcd");
        else
            $display("FAIL ❌: Expected 0xcd, got %h", rd_data[7:0]);


        #1000;
        $display("Simulation complete.");
        $stop;
    end
endmodule
