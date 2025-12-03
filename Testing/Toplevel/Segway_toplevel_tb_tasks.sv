package Segway_toplevel_tb_tasks_pkg;
    
    localparam logic [7:0] CMD_START     = 8'h47; // 'G'
    localparam logic [7:0] CMD_STOP      = 8'h53; // 'S'

    // Task to initialize all inputs to default values
    task automatic initialize_inputs(
        ref logic       clk,
        ref logic       RST_n,
        ref logic       send_cmd,
        ref logic signed [15:0] rider_lean,
        ref logic [11:0] ld_cell_lft,
        ref logic [11:0] ld_cell_rght,
        ref logic [11:0] steerPot,
        ref logic [11:0] batt,
        ref logic       OVR_I_lft,
        ref logic       OVR_I_rght
    );
        begin
            clk = 0;
            RST_n = 0;
            send_cmd = 0;
            rider_lean = 0;
            ld_cell_lft = 0;
            ld_cell_rght = 0;
            steerPot = 0;
            batt = 0;
            OVR_I_lft = 0;
            OVR_I_rght = 0;
        end
    endtask : initialize_inputs

    task automatic apply_reset(
        ref logic RST_n,
        ref logic clk
    );
        begin
            RST_n = 0;
            repeat (10) @(posedge clk);
            RST_n = 1;
            repeat (5) @(posedge clk);
        end
    endtask : apply_reset

    task automatic send_uart_byte(
        input logic [7:0] cmd,
        ref logic [7:0] tx_data,
        ref logic trmt,
        ref logic tx_done,
        ref logic clk
    );
    begin : send_uart_byte
            fork
                begin 
                    $display("Time=%0t: Sending command: 0x%02h ('%c')", $time, cmd, cmd);
                    tx_data = cmd;
                    trmt = 1;
                    @(posedge clk);
                    #1;
                    trmt = 0;
                    wait(tx_done == 1);
                    disable send_uart_byte;
                end 

                begin
                    repeat(10000000) @(posedge clk);
                    $display("ERROR: UART TRANSMISSION TIMED OUT! CMD: %h", cmd);
                    $stop;
                end
            join
        end
    endtask : send_uart_byte

    task automatic spi_transaction(
        input logic [15:0] tx_data,
        ref logic clk,
        ref logic wrt,
        ref logic [15:0] wrt_data,
        ref logic done,
        ref logic [15:0] rd_data
    );

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

    task automatic wait_for_INT(
        ref logic INT,
        ref logic clk
    );
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
    endtask : wait_for_INT

    task automatic run_standard_start_sequence(
        ref logic [7:0] tx_data,
        ref logic trmt,
        ref logic tx_done,
        ref logic clk
    );
        begin
            // Send START command
            send_uart_byte(CMD_START, tx_data, trmt, tx_done, clk);
            repeat(50) @(posedge clk); // wait some time
        end
    endtask : run_standard_start_sequence

    task automatic run_standard_stop_sequence(
        ref logic [7:0] tx_data,
        ref logic trmt,
        ref logic tx_done,
        ref logic clk
    );
        begin
            // Send STOP command
            send_uart_byte(CMD_STOP, tx_data, trmt, tx_done, clk);
            repeat(50) @(posedge clk); // wait some time
        end
    endtask : run_standard_stop_sequence

    task automatic set_loads(
        input int L,
        input int R,
        ref logic [11:0] ld_cell_lft,
        ref logic [11:0] ld_cell_rght,
        ref logic clk
    );
        begin
            ld_cell_lft  = L;
            ld_cell_rght = R;
            @(posedge clk);
            #1;
        end
    endtask : set_loads

    task automatic set_steerPot(
        input int value,
        ref logic [11:0] steerPot,
        ref logic clk
    );
        begin
            steerPot = value;
            @(posedge clk);
            #1;
        end
    endtask : set_steerPot

    task automatic set_batt(
        input int value,
        ref logic [11:0] batt,
        ref logic clk
    );
        begin
            batt = value;
            @(posedge clk);
            #1;
        end
    endtask : set_batt

    task automatic set_rider_lean(
        input signed [15:0] value,
        ref logic signed [15:0] rider_lean,
        ref logic clk
    );
        begin
            rider_lean = value;
            @(posedge clk);
            #1;
        end
    endtask : set_rider_lean

    task automatic check_if_signal_in_range(
        input int expected_max,
        input int expected_min,
        input int actual
    );
        begin
            if (actual > expected_max || actual < expected_min) begin
                $display("ERROR: Signal out of range! Actual: %0d, Expected Range: [%0d, %0d]", actual, expected_min, expected_max);
                $stop;
            end else begin
                $display("Signal within range: Actual: %0d, Expected Range: [%0d, %0d]", actual, expected_min, expected_max);
            end
        end
    endtask : check_if_signal_in_range

    task automatic check_condition(
        input string test_name,
        input logic condition,
        input string details
    );
        begin
            if (condition) begin
                $display("Time=%0t: PASS - %s | %s", $time, test_name, details);
            end else begin
                $display("Time=%0t: FAIL - %s | %s", $time, test_name, details);
                $stop;
            end
        end
    endtask : check_condition



task automatic riderStepOff(
    ref logic ld_cell_lft,
    ref logic  ld_cell_rght,
    ref logic clk
    );

    begin 
            set_loads(350,0, ld_cell_lft, ld_cell_rght, clk);
    end 
endtask


task automatic startStandardOperationProcedure(
    ref logic               clk,
    ref logic               RST_n,
    ref logic               send_cmd,
    ref logic signed [15:0] rider_lean,
    ref logic        [11:0] ld_cell_lft,
    ref logic        [11:0] ld_cell_rght,
    ref logic        [11:0] steerPot,
    ref logic        [11:0] batt,
    ref logic               OVR_I_lft,
    ref logic               OVR_I_rght,
    ref logic        [7:0]  tx_data,
    ref logic               trmt,
    ref logic               tx_done
);
    begin
        initialize_inputs(clk, RST_n, send_cmd,
                          rider_lean, ld_cell_lft, ld_cell_rght,
                          steerPot, batt, OVR_I_lft, OVR_I_rght);
        apply_reset(RST_n, clk);
        set_loads(350, 350, ld_cell_lft, ld_cell_rght, clk);
        repeat (40000) @(posedge clk);
        run_standard_start_sequence(tx_data, trmt, tx_done, clk);
    end
endtask : startStandardOperationProcedure



endpackage : Segway_toplevel_tb_tasks_pkg