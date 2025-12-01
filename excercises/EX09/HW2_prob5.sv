// Part a: The implementation of the d-latch is not correct because it uses a non-blocking assignment to assign d to q, so it does not hold the value of d when clk is high.
// Part e: The always_ff block is meant to used for flip-flops, but it does not always guarantee that latches will be synthesized. It might issue a warning if they are not, allowing the designer to catch the lack of flop earlier.
module latch(d, clk, q, rst);// d-latch with active high synchronous reset
    input d, clk, rst;
    output reg q;
    
    always_ff @(clk) begin
        if (clk) begin
            if (rst) 
                q = 0;
        q = d;
        end
    end
endmodule

module latch2(d, clk, q, rst_n, en); //d-latch with asynchronous active low reset, and a high active enable
    input d, clk, rst_n, en;
    output reg q;
    
    always_ff @(clk, negedge rst_n) begin
        if (!rst_n) 
            q = 0;
        else if (clk && en) 
            q = d;
    end
endmodule

module SR_latch(clk, s, r, q, rst_n); //SR-latch with active high synchronous reset, and an active high synchronous set, and an active low asynchronous reset
    input clk, s, r, rst_n;
    output reg q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            q = 0;
        else if (s && !r) 
            q = 1;
        else if (!s && r) 
            q = 0;
        else if (s && r)
            q = 0; // priority to r
        else
            q = q;
    end
endmodule
