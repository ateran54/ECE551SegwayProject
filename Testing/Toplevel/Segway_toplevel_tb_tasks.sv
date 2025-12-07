package Segway_toplevel_tb_tasks_pkg;
    
    localparam logic [7:0] CMD_START     = 8'h47; // 'G'
    localparam logic [7:0] CMD_STOP      = 8'h53; // 'S'

    //enum for turn direction
    typedef enum logic [1:0] {
        TURN_NONE = 2'b00,
        TURN_LEFT = 2'b01,
        TURN_RIGHT= 2'b10
    } turn_dir_e;

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
        $display("Initializing inputs...");
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

    //task to check both turn diretion and that platform is balanced
    task automatic check_balance_and_turn_direction(
        ref logic signed [15:0] theta_platform,
        ref logic signed [15:0] omega_lft,
        ref logic signed [15:0] omega_rght,
        input turn_dir_e expected_direction,
        ref logic clk
    );
        begin
            check_platform_is_balanced(theta_platform, clk);
            check_turn_direction(omega_lft, omega_rght, expected_direction);
        end
    endtask : check_balance_and_turn_direction

    task automatic check_platform_is_balanced(
        ref logic signed [15:0] theta_platform,
        ref logic clk
    );
        begin
            if ( (theta_platform <= 200) && (theta_platform >= -200) ) begin
                $display("TEST: PLATFORM BALANCED : PASSED — theta_platform = %0d", theta_platform);
            end 
            else begin
                $display("TEST: PLATFORM BALANCED : FAILED — theta_platform = %0d", theta_platform);
                $stop;
            end
        end
    endtask : check_platform_is_balanced

    task automatic check_turn_direction(
        ref logic signed [15:0] omega_lft,
        ref logic signed [15:0] omega_rght,
        input turn_dir_e expected_direction
    );
        begin
            case (expected_direction) 
                TURN_NONE: begin
                    if ( (omega_lft == omega_rght) ) begin
                        $display("TEST: TURN DIRECTION NONE : PASSED");
                    end 
                    else begin
                        $display("TEST: TURN DIRECTION NONE : FAILED — omega_lft = %0d, omega_rght = %0d", omega_lft, omega_rght);
                        $stop;
                    end
                end

                TURN_LEFT: begin
                    if ( (omega_lft < omega_rght) ) begin
                        $display("TEST: TURN DIRECTION LEFT : PASSED");
                    end 
                    else begin
                        $display("TEST: TURN DIRECTION LEFT : FAILED — omega_lft = %0d, omega_rght = %0d", omega_lft, omega_rght);
                        $stop;
                    end
                end

                TURN_RIGHT: begin
                    if ( (omega_lft > omega_rght) ) begin
                        $display("TEST: TURN DIRECTION RIGHT : PASSED");
                    end 
                    else begin
                        $display("TEST: TURN DIRECTION RIGHT : FAILED — omega_lft = %0d, omega_rght = %0d", omega_lft, omega_rght);
                        $stop;
                    end
                end

                default: begin
                    $display("ERROR: INVALID EXPECTED DIRECTION!");
                    $stop;
                end
            endcase
        end
    endtask : check_turn_direction


    task automatic apply_reset(
        ref logic RST_n,
        ref logic clk
    );
        begin
            RST_n = 0;
            repeat (10) @(posedge clk);
            @(negedge clk);
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
    ref logic [11:0] ld_cell_lft,
    ref logic [11:0] ld_cell_rght,
    ref logic clk
    );

    begin 
            set_loads(350,0, ld_cell_lft, ld_cell_rght, clk);
    end 
endtask




task automatic assert_all_omegas_zero(
    ref logic signed [15:0] omega_platform,
    ref logic signed [15:0] omega_lft,
    ref logic signed [15:0] omega_rght
);
    if (omega_platform == 0 &&
        omega_lft      == 0 &&
        omega_rght     == 0) begin

        $display("TEST: PHYSICS OMEGAS : PASSED — all omegas are zero");
    end 
    else begin
        $display("TEST: PHYSICS OMEGAS : FAILED");
        $display("  omega_platform = %0d", omega_platform);
        $display("  omega_lft      = %0d", omega_lft);
        $display("  omega_rght     = %0d", omega_rght);
        $stop;
    end
endtask




task automatic assert_all_speeds_zero(
    ref logic signed [15:0] lft_speed,
    ref logic signed [15:0] rght_speed
);
    if (lft_speed == 0 &&
        rght_speed      == 0 ) begin

        $display("TEST: SPEED  : PASSED — all Speeds are zero");
    end 
    else begin
        $display("TEST: SPEED : FAILED");
        $display("  lft_speed      = %0d", lft_speed);
        $display("  rght_speed     = %0d", rght_speed);
        $stop;
    end

endtask
task automatic assert_all_omegas_not_zero(
    ref logic signed [15:0] omega_platform,
    ref logic signed [15:0] omega_lft,
    ref logic signed [15:0] omega_rght
);
    if( (omega_platform != 0 &&
        omega_lft      != 0 &&
        omega_rght     != 0)) begin

        $display("TEST: PHYSICS OMEGAS : PASSED — all omegas are not zero");
    end 
    else begin
        $display("TEST: PHYSICS OMEGAS : FAILED");
        $display("  omega_platform = %0d", omega_platform);
        $display("  omega_lft      = %0d", omega_lft);
        $display("  omega_rght     = %0d", omega_rght);
        $stop;
    end
endtask


endpackage : Segway_toplevel_tb_tasks_pkg