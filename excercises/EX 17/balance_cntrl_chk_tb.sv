module balance_cntrl_chk_tb();
reg clk;

reg [48:0] stim;
wire [24:0] actual_resp;

reg [48:0] stim_mem [0:1499];
reg [24:0] resp_mem [0:1499];

wire signed [11:0] lft_spd;
wire signed [11:0] rght_spd; 
wire too_fast;

assign actual_resp = {lft_spd, rght_spd, too_fast};

integer errors = 0;
integer i;

initial begin
  
    clk = 0;
    
    $readmemh("balance_cntrl_stim.hex", stim_mem);
    $readmemh("balance_cntrl_resp.hex", resp_mem);
    
    force iDUT.u_pid.ss_tmr = 8'hFF;
    
    $display("Starting balance_cntrl testbench with 1500 vectors...");
    
    for (i = 0; i < 1500; i = i + 1) begin
        // Apply stimulus vector to DUT inputs
        stim = stim_mem[i];
        
        // Wait for positive edge of clock
        @(posedge clk);
        
        // Wait 1 time unit after clock rise
        #1;
        
        // Check if actual response matches expected response
        if (actual_resp !== resp_mem[i]) begin
            errors = errors + 1;
            $display("ERROR at vector %0d:", i);
            $display("  Expected: 0x%h, Got: 0x%h", resp_mem[i], actual_resp);
            $display("  Stimulus: rst_n=%b vld=%b ptch=0x%h ptch_rt=0x%h pwr_up=%b rider_off=%b steer_pot=0x%h en_steer=%b",
                     stim[48], stim[47], stim[46:31], stim[30:15], stim[14], stim[13], stim[12:1], stim[0]);
            $display("  Expected: lft_spd=0x%h rght_spd=0x%h too_fast=%b", 
                     resp_mem[i][24:13], resp_mem[i][12:1], resp_mem[i][0]);
            $display("  Actual:   lft_spd=0x%h rght_spd=0x%h too_fast=%b", 
                     lft_spd, rght_spd, too_fast);
            
            // Stop after first few errors to avoid overwhelming output
            if (errors >= 10) begin
                $display("Stopping after 10 errors...");
                $stop();
            end
        end
    end
    
    // Final results
    if (errors == 0) begin
        $display("SUCCESS: All 1500 vectors passed!");
    end else begin
        $display("FAILED: %0d vectors had mismatches out of 1500", errors);
    end
    
    $stop();
end

// Clock generation - toggle every 5 time units
always #5 clk = ~clk;

// Instantiate DUT (balance_cntrl module)
balance_cntrl #(.fast_sim(1)) iDUT (
    .clk(clk),
    .rst_n(stim[48]),
    .vld(stim[47]), 
    .ptch(stim[46:31]),
    .ptch_rt(stim[30:15]),
    .pwr_up(stim[14]),
    .rider_off(stim[13]),
    .steer_pot(stim[12:1]),
    .en_steer(stim[0]),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .too_fast(too_fast)
);

endmodule
