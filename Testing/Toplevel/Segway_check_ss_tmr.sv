module Segway_check_ss_tmr();

import Segway_toplevel_tb_tasks_pkg::*;

//// Interconnects to DUT/support defined as type wire /////
logic SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
logic A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
logic RX_TX;
logic PWM1_rght, PWM2_rght, PWM1_lft, PWM2_lft;
logic piezo,piezo_n;
logic cmd_sent;
logic rst_n;					// synchronized global reset
////// Stimulus is declared as type reg ///////
logic clk, RST_n;
logic [7:0] cmd;				// command host is sending to DUT
logic send_cmd;				// asserted to initiate sending of command
logic signed [15:0] rider_lean;
logic [11:0] ld_cell_lft, ld_cell_rght,steerPot,batt;	// A2D values
logic OVR_I_lft, OVR_I_rght;

///// Internal registers for testing purposes??? /////////


////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM1_lft(PWM1_lft),
				  .PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
				  .PWM2_rght(PWM2_rght),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
ADC128S_FC iA2D(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
             .MISO(A2D_MISO),.MOSI(A2D_MOSI),.ld_cell_lft(ld_cell_lft),.ld_cell_rght(ld_cell_rght),
			 .steerPot(steerPot),.batt(batt));			
	 
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.INERT_INT(INT),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.PWM1_lft(PWM1_lft),.PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
			.PWM2_rght(PWM2_rght),.OVR_I_lft(OVR_I_lft),.OVR_I_rght(OVR_I_rght),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));

//// Instantiate UART_tx (mimics command from BLE module) //////
UART_tx iTX(.clk(clk),.rst_n(rst_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

/////////////////////////////////////
// Instantiate reset synchronizer //
///////////////////////////////////
rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));// Clock generation

initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time unit clock period
end

initial begin
    $display("Starting PID ss_counter increment testbench (with Segway start sequence)");

    initialize_inputs(clk, RST_n, send_cmd, rider_lean, ld_cell_lft, ld_cell_rght, steerPot, batt, OVR_I_lft, OVR_I_rght);
    apply_reset(RST_n, clk);
    //wait for a bit before rider goes on
    repeat (100) @(posedge clk);
    //set steerpot and wait for a bit
    set_steerPot(12'h0800, steerPot, clk);
    repeat (40000) @(posedge clk);
    //set loads and wait for balance check
    set_loads(330,330, ld_cell_lft, ld_cell_rght, clk);
    repeat (40000) @(posedge clk);
    //send start command and wait a bit
    send_uart_byte(CMD_START, cmd, send_cmd, cmd_sent, clk);
    @(posedge clk);
    #1;

    // Capture initial counter value
    logic [26:0] prev_val;
    prev_val = dut.ss_counter;

    integer cycles_checked = 0;
    integer max_cycles = 2000; // safety cap

    // Loop and check increment by 256 while top bits [26:19] are not all ones
    forever begin
        @(posedge clk);
        cycles_checked = cycles_checked + 1;

        // If the terminal condition (all ones) has been reached, exit successfully
        if (&dut.ss_counter[26:19]) begin
            $display("Reached terminal condition at time %0t. ss_counter = %0d, ss_tmr = %0d", $time, dut.ss_counter, dut.ss_counter[26:19]);
            $display("TEST PASSED: ss_counter stopped incrementing when top bits became all ones.");
            $stop;
        end

        // While not all ones, expect increment of 256
        logic [26:0] expected;
        expected = prev_val + 27'd256;
        if (dut.ss_counter !== expected) begin
            $display("ERROR at time %0t: ss_counter did not increment by 256. prev=%0d expected=%0d actual=%0d ss_tmr=%0d", $time, prev_val, expected, dut.ss_counter, dut.ss_counter[26:19]);
            $stop;
        end
        prev_val = dut.ss_counter;

        if (cycles_checked > max_cycles) begin
            $display("ERROR: exceeded max cycles without hitting terminal condition. last ss_counter=%0d ss_tmr=%0d", dut.ss_counter, dut.ss_counter[26:19]);
            $stop;
        end
    end
end

endmodule