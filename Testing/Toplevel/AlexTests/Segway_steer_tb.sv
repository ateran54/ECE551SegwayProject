//Applying a steer pot value for a right and left turns gives proper left and right speed values as well as making segway angle converge to around 0

module Segway_steer_tb();

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
rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

initial begin
  $display("Starting Segway Steer Testbench Simulation");  

  $display("Checking getting of mid balancing: Checking if the right and left velocities values are valid ")
  startStandardOperation();
  repeat (40000) @(posedge clk);
  set_rider_lean(16'h0000, rider_lean, clk);
  repeat (40000) @(posedge clk);
  riderStepOff(ld_cell_lft,ld_cell_rght,clk);
  repeat (40000) @(posedge clk);
  assert_en_sterr_low();
  assert_all_omegas_zero();
  

  
  $display("END OF SIMULATION");
  $stop();
end



task automatic assert_en_sterr_low()
  assert (iDUT.en_steer==0) $display("TEST: BALNCE CNTRL/SAFETY : PASSED");
  else   $display("TEST: BALNCE CNTRL/SAFETY : FAILED : Balance theta did not converge to right value");
endtask

task automatic startStandardOperation();
  startStandardOperationProcedure(clk,RST_n,send_cmd,rider_lean,ld_cell_lft,
      ld_cell_rght,steerPot,batt,OVR_I_lft
      ,OVR_I_rght,tx_data,trmt,tx_done);
endtask


always
  #10 clk = ~clk;

endmodule	
