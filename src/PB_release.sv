module PB_release (
    input logic PB,
    input rst_n,
    input clk,
    output logic released
);
    logic flop_1_out;
    logic flop_2_out;
    logic flop_3_out;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            flop_1_out <= 1;
        else
            flop_1_out <= PB;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            flop_2_out <= 1;
        else
            flop_2_out <= flop_1_out;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            flop_3_out <= 1;
        else
            flop_3_out <= flop_2_out;
    end

    assign released = flop_2_out & ~flop_3_out;



endmodule
