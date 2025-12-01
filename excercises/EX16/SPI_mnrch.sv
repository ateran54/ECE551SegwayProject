module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);

  input clk, rst_n;             // 50MHz system clock and reset
  input MISO;                   // Master In Serf Out
  input wrt;                    // Write trigger - high for 1 clock initiates SPI transaction
  input [15:0] wt_data;         // Data to send to serf device
  
  output reg SS_n;              // Active low Serf Select
  output SCLK;                  // Serial Clock (1/16 of system clock)
  output MOSI;                  // Master Out Serf In
  output reg done;              // Transaction complete flag
  output reg [15:0] rd_data;    // Data received from serf device


  // Internal signals and registers

  // State machine states
  typedef enum reg [1:0] {IDLE, TRANSMIT, BACK_PORCH} state_t;
  state_t state, nstate;
  
  // Counters and control signals
  reg [3:0] SCLK_div;           // 4-bit counter for SCLK generation
  reg [3:0] bit_cntr;           // Bit counter for tracking shift operations
  reg [15:0] shft_reg;          // Main 16-bit shift register
  reg MISO_smpl;                // Sampled version of MISO
  
  // State machine control signals
  reg init;                     // Initialize counters and registers
  reg shft;                     // Enable shift register
  reg ld_SCLK;                  // Load SCLK_div for front porch
  reg set_done;                 // Set done flag
  

  // SCLK generation from 4-bit counter 
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      SCLK_div <= 4'b1011;
    else if (ld_SCLK)
      SCLK_div <= 4'b1011;      
    else if (state != IDLE)
      SCLK_div <= SCLK_div + 1;
    else
      SCLK_div <= 4'b1011;    
  end
  
  assign SCLK = SCLK_div[3];
  
  wire SCLK_rise_next = (SCLK_div == 4'b0111);    
  wire SCLK_fall_next = (SCLK_div == 4'b1111);    
  wire shft_imm = SCLK_fall_next;                  
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      MISO_smpl <= 1'b0;
    else if (SCLK_rise_next && (state == TRANSMIT))
      MISO_smpl <= MISO;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      shft_reg <= 16'h0000;
    else if (init)
      shft_reg <= wt_data;       
    else if (shft && shft_imm)
      shft_reg <= {shft_reg[14:0], MISO_smpl};  
  end
  
  assign MOSI = shft_reg[15];
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      bit_cntr <= 4'h0;
    else if (init)
      bit_cntr <= 4'h0;
    else if (shft && shft_imm)
      bit_cntr <= bit_cntr + 1;
  end

  wire done15 = (bit_cntr == 4'hF);
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      SS_n <= 1'b1;            
    else if (init)
      SS_n <= 1'b0;           
    else if (set_done)
      SS_n <= 1'b1;            
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      done <= 1'b0;
    else if (wrt)
      done <= 1'b0;            
    else if (set_done)
      done <= 1'b1;            
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      rd_data <= 16'h0000;
    else if (set_done)
      rd_data <= shft_reg;      
  end
  
  
  // State machine 
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nstate;
  end

  
  always_comb begin
    nstate = IDLE;
    init = 1'b0;
    shft = 1'b0;
    ld_SCLK = 1'b0;
    set_done = 1'b0;
    
    case (state)
      IDLE: begin
        if (wrt) begin
          init = 1'b1;          
          ld_SCLK = 1'b1;       
          nstate = TRANSMIT;
        end
        else
          nstate = IDLE;
      end
      
      TRANSMIT: begin
        shft = 1'b1;            
        if (done15 && shft_imm) begin
          nstate = BACK_PORCH;  
        end
        else
          nstate = TRANSMIT;
      end
      
      BACK_PORCH: begin
        set_done = 1'b1;        
        nstate = IDLE;
      end
      
      default: nstate = IDLE;
    endcase
  end

endmodule
