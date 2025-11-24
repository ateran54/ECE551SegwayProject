module A2D_test(clk,RST_n,SEL,LED,SCLK,SS_n,MOSI,MISO);

  input clk,RST_n;		// clk and unsynched reset from PB
  input SEL;			// from 2nd PB, cycle through outputs
  input MISO;			// from A2D
  
  output [7:0] LED;
  output SS_n;			// active low slave select to A2D
  output SCLK;			// SCLK to A2D SPI
  output MOSI;
  
  ////////////////////////////////////////////////////////////
  // Declare any needed internal registers (like counters) //
  //////////////////////////////////////////////////////////
  logic [18:0] conv_rate_cnt;
  logic [1:0] led_cntr;
  logic [11:0] lft_ld,rght_ld,steer_pot,batt;
  ///////////////////////////////////////////////////////
  // Declare any needed internal signals as type wire //
  /////////////////////////////////////////////////////
  logic full;
  logic en_2bit;
  logic rst_n;
  //////////////////////////////////////////////////
  // Infer 19-bit counter to set conversion rate //
  ////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      conv_rate_cnt <= 19'b0;
    else
      conv_rate_cnt <= conv_rate_cnt + 1;

  assign full = &conv_rate_cnt;
  ////////////////////////////////////////////////////////////////
  // Infer 2-bit counter to select which output to map to LEDs //
  //////////////////////////////////////////////////////////////
  always_ff @(posedge clk) begin
    if (!rst_n)
      led_cntr <= 2'b0;
    else if (en_2bit)
      led_cntr <= led_cntr + 1;
  end
  //////////////////////////////////////////////////////
  // Infer Mux to select which output to map to LEDs //
  //////////////////////////////////////////////////// 
  assign LED = (led_cntr == 2'b00) ? lft_ld[11:4] :
                    (led_cntr == 2'b01) ? rght_ld[11:4] :
                    (led_cntr == 2'b10) ? steer_pot[11:4]:
                    batt[11:4];
	
  //////////////////////
  // Instantiate DUT //
  ////////////////////  
  A2D_intf iDUT(.clk(clk),.rst_n(rst_n),.nxt(full),.lft_ld(lft_ld),
                .rght_ld(rght_ld),.steer_pot(steer_pot),.batt(batt),
				.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));
			   
  ///////////////////////////////////////////////
  // Instantiate Push Button release detector //
  /////////////////////////////////////////////
  PB_release iPB(.clk(clk),.rst_n(rst_n),.PB(SEL),.released(en_2bit));
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));   
	  
endmodule
  