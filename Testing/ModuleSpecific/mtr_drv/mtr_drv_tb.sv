module mtr_drv_tb();

  /////////////////////////////////////////
  // Declare stimulus as type reg       //
  /////////////////////////////////////////
  reg clk, rst_n;
  reg [11:0] lft_spd, rght_spd;
  reg OVR_I_lft, OVR_I_rght;
  
  ///////////////////////////////////////////
  // Declare internal signals to observe //
  /////////////////////////////////////////
  wire PWM1_lft, PWM2_lft, PWM1_rght, PWM2_rght;
  wire OVR_I_shtdwn;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  mtr_drv iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .OVR_I_lft(OVR_I_lft),
    .OVR_I_rght(OVR_I_rght),
    .PWM1_lft(PWM1_lft),
    .PWM2_lft(PWM2_lft),
    .PWM1_rght(PWM1_rght),
    .PWM2_rght(PWM2_rght),
    .OVR_I_shtdwn(OVR_I_shtdwn)
  );
  
  ///////////////////////////////////
  // Clock generation (50MHz)     //
  ///////////////////////////////////
  initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 20ns period = 50MHz
  end
  
  ///////////////////////////////////
  // Main test procedure          //
  ///////////////////////////////////
  initial begin
    // Initialize signals
    rst_n = 0;
    lft_spd = 12'h000;
    rght_spd = 12'h000;
    OVR_I_lft = 0;
    OVR_I_rght = 0;
    
    // Apply reset
    @(posedge clk);
    @(negedge clk) rst_n = 1;
    
    $display("============================================================");
    $display("TEST 1: OVR_I pulses WITHIN blanking window");
    $display("Should NOT cause OVR_I_shtdwn to assert");
    $display("============================================================");
    
    // Set motor speeds to generate PWM activity
    lft_spd = 12'h400;   // Positive speed
    rght_spd = 12'h400;
    
    // Wait for a few PWM cycles to stabilize
    repeat(5) @(posedge iDUT.iPWM_lft.PWM_synch);
    
    // Test 1: Generate 45 OVR_I pulses WITHIN blanking window
    // These should be ignored and NOT increment OVR_I_cnt
    repeat(45) begin
      // Wait for blanking period to be active
      @(posedge iDUT.iPWM_lft.ovr_I_blank);
      
      // Generate OVR_I pulse during blanking
      @(posedge clk);
      #1 OVR_I_lft = 1;
      repeat(3) @(posedge clk);
      #1 OVR_I_lft = 0;
      
      // Wait for next PWM cycle
      @(posedge iDUT.iPWM_lft.PWM_synch);
    end
    
    // Wait a bit and check that shutdown did NOT occur
    repeat(10) @(posedge clk);
    
    if (OVR_I_shtdwn) begin
      $display("ERROR: OVR_I_shtdwn asserted when pulses were in blanking window!");
      $display("TEST 1 FAILED");
      $stop;
    end else begin
      $display("PASS: OVR_I_shtdwn did NOT assert (as expected)");
      $display("OVR_I_cnt = %d (should be 0 or very low)", iDUT.OVR_I_cnt);
      $display("TEST 1 PASSED");
    end
    
    $display("\n============================================================");
    $display("TEST 2: OVR_I pulses OUTSIDE blanking window");
    $display("Should cause OVR_I_shtdwn to assert after ~31 occurrences");
    $display("============================================================");
    
    // Reset the DUT
    @(negedge clk) rst_n = 0;
    repeat(5) @(posedge clk);
    @(negedge clk) rst_n = 1;
    
    // Reset OVR_I signals
    OVR_I_lft = 0;
    OVR_I_rght = 0;
    
    // Set motor speeds again
    lft_spd = 12'h400;
    rght_spd = 12'h400;
    
    // Wait for stabilization
    repeat(5) @(posedge iDUT.iPWM_lft.PWM_synch);
    
    // Test 2: Generate 45 OVR_I pulses OUTSIDE blanking window
    // These should increment OVR_I_cnt and eventually cause shutdown
    repeat(45) begin
      // Wait for PWM_synch (start of new cycle)
      @(posedge iDUT.iPWM_lft.PWM_synch);
      
      // Wait for blanking to end
      @(negedge iDUT.iPWM_lft.ovr_I_blank);
      
      // Generate OVR_I pulse outside blanking period
      repeat(10) @(posedge clk);  // Delay into non-blanking region
      #1 OVR_I_rght = 1;
      repeat(5) @(posedge clk);
      #1 OVR_I_rght = 0;
    end
    
    // Check if shutdown occurred
    repeat(10) @(posedge clk);
    
    if (!OVR_I_shtdwn) begin
      $display("ERROR: OVR_I_shtdwn did NOT assert when it should have!");
      $display("OVR_I_cnt = %d (should be 31)", iDUT.OVR_I_cnt);
      $display("TEST 2 FAILED");
      $stop;
    end else begin
      $display("PASS: OVR_I_shtdwn asserted (as expected)");
      $display("OVR_I_cnt = %d", iDUT.OVR_I_cnt);
      $display("TEST 2 PASSED");
    end
    
    $display("\n============================================================");
    $display("ALL TESTS PASSED!");
    $display("============================================================");
    
    $stop;
  end
  
  ///////////////////////////////////
  // Timeout watchdog             //
  ///////////////////////////////////
  initial begin
    #500000000;  // 500ms timeout
    $display("ERROR: Simulation timeout!");
    $stop;
  end
  
endmodule
