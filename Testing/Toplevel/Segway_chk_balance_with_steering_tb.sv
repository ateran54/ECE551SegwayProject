module Segway_lean_steerpot_conv_tb();

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
  $display("Starting Segway Lean Testing with Steering Testbench Simulation");
  //init inputs and apply reset
  $display("Initializing inputs...");
  initialize_inputs(clk, RST_n, send_cmd, rider_lean, ld_cell_lft, ld_cell_rght, steerPot, batt, OVR_I_lft, OVR_I_rght);
  apply_reset(RST_n, clk);

  $display("Rider is getting on the Segway...");
  //set loads and wait for balance check
  set_loads(330,320, ld_cell_lft, ld_cell_rght, clk);
  repeat (40000) @(posedge clk);
  //send start command
  run_standard_start_sequence(cmd, send_cmd, cmd_sent, clk);
  //lean forward and wait
  repeat (700000) @(posedge clk);
  $display("Leaning forward with rider_lean = 0x0FFF while steering to the right...");
  set_rider_lean(16'h0FFF, rider_lean, clk);
  //set steerpot to steer to the right
  set_steerPot(12'hD00, steerPot, clk);

  repeat (2000000) @(posedge clk);
  //Check that theta platform angle is less than 300 
  check_condition("TEST: Theta Platform Angle Range For Forward Lean with Steering", (iPHYS.theta_platform <= THETA_PLATFORM_ZERO_THRESHOLD) && (iPHYS.theta_platform >= -THETA_PLATFORM_ZERO_THRESHOLD), $sformatf("Value: %0d", iPHYS.theta_platform));
  //check that left and right omega reflect a right turn (right wheel slower than left)
  check_condition("TEST: Left and Right Wheel Omega for Right Turn", (iPHYS.omega_lft > iPHYS.omega_rght), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));
  $display("Leaning back to neutral while maintaining right steer...");
  set_rider_lean(16'h0000, rider_lean, clk);
  repeat (2000000) @(posedge clk);
  //Check that theta platform angle is less than 300 
  check_condition("TEST: Theta Platform Angle Range For Forward Lean with Steering", (iPHYS.theta_platform <= THETA_PLATFORM_ZERO_THRESHOLD) && (iPHYS.theta_platform >= -THETA_PLATFORM_ZERO_THRESHOLD), $sformatf("Value: %0d", iPHYS.theta_platform));
  //check that left and right omega reflect a right turn (right wheel slower than left)
  check_condition("TEST: Left and Right Wheel Omega for Right Turn", (iPHYS.omega_lft > iPHYS.omega_rght), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));


  //now, lets check left turn by doing a sudden swerve to left by rapidly changing the steerpot
  set_steerPot(12'h400, steerPot, clk);
  set_rider_lean(16'h0FFF, rider_lean, clk);
  repeat (2000000) @(posedge clk);
  //Check that theta platform angle is less than 300 
  check_condition("TEST: Theta Platform Angle Range For Forward Lean with Steering", (iPHYS.theta_platform <= THETA_PLATFORM_ZERO_THRESHOLD) && (iPHYS.theta_platform >= -THETA_PLATFORM_ZERO_THRESHOLD), $sformatf("Value: %0d", iPHYS.theta_platform));
  //check that left and right omega reflect a left turn (left wheel slower than right)
  check_condition("TEST: Left and Right Wheel Omega for Left Turn", (iPHYS.omega_lft < iPHYS.omega_rght), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));
  set_rider_lean(16'h0000, rider_lean, clk);
  //set the steerpot to zero and wait for a bit and check if the omegas are equal again 
  set_steerPot(12'h800, steerPot, clk);
  repeat (12000000) @(posedge clk);
    //Check that theta platform angle is less than 250 
  check_condition("TEST: Theta Platform Angle Range For Forward Lean with Steering", (iPHYS.theta_platform <= THETA_PLATFORM_ZERO_THRESHOLD) && (iPHYS.theta_platform >= -THETA_PLATFORM_ZERO_THRESHOLD), $sformatf("Value: %0d", iPHYS.theta_platform));
  //check that left and right omega reflect a left turn (left wheel slower than right)
  check_condition("TEST: Left and Right Wheel Omega Equality After Steering Neutral", (iPHYS.omega_lft == iPHYS.omega_rght), $sformatf("Left Omega: %0d, Right Omega: %0d", iPHYS.omega_lft, iPHYS.omega_rght));
  $display("END OF SIMULATION");
  $stop();
end

always
  #10 clk = ~clk;

endmodule	
