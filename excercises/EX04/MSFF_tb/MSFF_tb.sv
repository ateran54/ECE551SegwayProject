module MSFF_tb();

    // Declare testbench signals
    logic clk;
    logic d;
    logic q;
    
    // Instantiate the MSFF
    MSFF DUT(.clk(clk), .d(d), .q(q));
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        d = 0;
        @(posedge clk);
        
        // Test case 1: D=1
        d = 1;
        @(posedge clk);
        if (q !== 1) $error("Test 1 failed: Expected q=1, got %b", q);
        
        // Test case 2: D=0
        d = 0;
        @(posedge clk);
        if (q !== 0) $error("Test 2 failed: Expected q=0, got %b", q);
        
        // Test case 3: Setup time test
        d = 1;
        #4;  // Change D close to clock edge
        @(posedge clk);
        if (q !== 1) $error("Test 3 failed: Expected q=1, got %b", q);
        
        // Test case 4: Hold time test
        d = 0;
        @(posedge clk);
        #1 d = 1;  // Change D shortly after clock edge
        if (q !== 0) $error("Test 4 failed: Expected q=0, got %b", q);
        
        // Test completion
        #20;
        $display("All tests completed!");
        $stop;
    end
    
    // Optional waveform generation
    initial begin
        $dumpfile("MSFF_tb.vcd");
        $dumpvars(0, MSFF_tb);
    end

endmodule