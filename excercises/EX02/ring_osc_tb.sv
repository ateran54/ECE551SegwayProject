//Generate a test bench for the file ring_osc.sv that instantiates the module ring_osc then set en to 
//low for 15 time units and then raise it to high
module ring_osc_tb();

  // Declare signal to drive the ring oscillator
  logic en;
  logic out;

  // Instantiate the ring oscillator
  ring_osc iDUT(.en(en), .out(out));

  // Test stimulus
  initial begin
    // Initialize enable to 0
    en = 1'b0;
    
    // Wait for 15 time units
    #15;
    
    // Set enable high
    en = 1'b1;
    
    // Let it run for a while to observe oscillation
    #100;
    
    $stop;
  end
endmodule
