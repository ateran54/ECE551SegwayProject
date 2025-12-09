// - Sending auth code starts the segway
//Sending stop code stops the segway
//Auth flow, start segway, apply some steering inputs, then stop it
module Segway_auth_flow_tb();

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

  $display("Starting Segway Auth block flow verifcation");
    //init inputs and apply reset
  initialize_inputs(clk, RST_n, send_cmd, rider_lean, ld_cell_lft, ld_cell_rght, steerPot, batt, OVR_I_lft, OVR_I_rght);
  apply_reset(RST_n, clk);
  set_steerPot(12'h0800, steerPot, clk);
  //wait for a bit before rider goes on
  repeat (100) @(posedge clk);
  //set steerpot and wait for a bit
  
  repeat (800000) @(posedge clk);
  //set loads and wait for balance check

  //check that the platform is zero
  check_condition("TEST: Platform velocity is zero currently", (iPHYS.omega_platform <= 5), $sformatf("Omega Platform: %0d", iPHYS.omega_platform));

  //send start command and wait a bit
  run_standard_start_sequence(cmd, send_cmd, cmd_sent, clk);
  repeat (1400000) @(posedge clk);
  //check that the left and right speeds are zero
  check_condition("TEST: Left and Right Wheel Omega are zero after start sequence", (iPHYS.omega_lft == 0) && (iPHYS.omega_rght == 0), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));
  check_condition("TEST: Platform velocity is zero after start sequence", (iPHYS.omega_platform <= 5 && iPHYS.omega_platform >= -5), $sformatf("Omega Platform: %0d", iPHYS.omega_platform));

  //set_loads(480,480, ld_cell_lft, ld_cell_rght, clk);
  //repeat (400000) @(posedge clk);
  // $display("Sending standard stop sequence to power down segway");
  // run_standard_stop_sequence(cmd, send_cmd, cmd_sent, clk);
  // //Check that pwr_up is still high since the loads are still present
  // check_condition("TEST: Power Up Signal still active after stop command sent since rider is still on segway.", (iDUT.pwr_up == 1), $sformatf("Value: %0d", iDUT.pwr_up));
  // //Now, set loads to zero to simulate getting off the segway
  // set_loads(0,0, ld_cell_lft, ld_cell_rght, clk);
  // repeat (400000) @(posedge clk);
  // //Check that pwr_up is now low since the loads are gone
  // check_condition("TEST: Power Up Signal Deactive after rider gets off.", (iDUT.pwr_up == 0), $sformatf("Value: %0d", iDUT.pwr_up));
  // //Check that all omegas are now zero
  // check_condition("TEST: Left and Right Wheel Omega are zero after rider gets off", (iPHYS.omega_lft == 0) && (iPHYS.omega_rght == 0), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));


  // //Now, set the loads back to normal to simulate getting back on the segway
  // set_loads(330,330, ld_cell_lft, ld_cell_rght, clk);
  // repeat (40000) @(posedge clk);



  // // This test pwr up signal an steer en. When rider gets off, pwr up deasserts and steer en deasserts.
  // // rider does not get off
  // $display("Auth flow testbench: pulsing the auth and seeing what happnes");
  // repeat (40000) @(posedge clk); // some space
  // run_standard_stop_sequence( cmd, send_cmd, cmd_sent, clk);
  // repeat (40000) @(posedge clk);
  // run_standard_start_sequence(cmd, send_cmd, cmd_sent, clk);
  // repeat (40000) @(posedge clk);
  // run_standard_stop_sequence( cmd, send_cmd, cmd_sent, clk);
  // repeat (40000) @(posedge clk);
  // asssrtNettorqueZero();

  // assert_en_sterr_low();

  // // This test pwr up signal an steer en. When rider gets off, pwr up deasserts and steer en deasserts.
  // // rider does not get off
  // $display("Auth flow testbench: aplying some sterring inputs");
  // repeat (40000) @(posedge clk);
  // set_steerPot(2047, steerPot, clk);
  // repeat (40000) @(posedge clk);
  // run_standard_stop_sequence(cmd, send_cmd, cmd_sent, clk);
  // set_steerPot(2047, steerPot, clk);
  // repeat (40000) @(posedge clk);
  // asssrtNettorqueZero();
  // assert_en_sterr_low();

  //   // This test pwr up signal an steer en. When rider gets off, pwr up deasserts and steer en deasserts.
  // // rider does  get off
  // $display("Auth flow testbench: aplying some sterring inputs and getting off first");
  // repeat (40000) @(posedge clk);
  // set_steerPot(2047, steerPot, clk);
  // repeat (40000) @(posedge clk);
  // set_steerPot(2047, steerPot, clk);
  // run_standard_stop_sequence(cmd, send_cmd, cmd_sent, clk);
  // assert_en_sterr_low();
    
  $display("END OF SIMULATION");
  $stop();
end




task automatic asssrtNettorqueZero();
    check_condition("TEST: NET TORQUE ZERO: ", (iPHYS.net_torque == 0), $sformatf("Value: %0d", iPHYS.net_torque));
endtask


task automatic assert_en_sterr_low();
    check_condition("TEST: BALNCE CNTRL/SAFETY: ENABLE STEER LOW: ", (iDUT.en_steer == 0), $sformatf("Value: %0d", iDUT.en_steer));
endtask

always
  #10 clk = ~clk;

endmodule	