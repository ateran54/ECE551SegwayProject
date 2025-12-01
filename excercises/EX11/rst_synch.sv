module rst_synch (
    input  logic clk,     // clock
    input  logic RST_n,   // raw async reset input (active low, from pushbutton)
    output logic rst_n    // synchronized global reset (active low)
);
    logic sync1, sync2;

    always_ff @(negedge clk or negedge RST_n) begin
        if (!RST_n) begin
            sync1 <= 1'b0;
            sync2 <= 1'b0;
        end else begin
            // Release synchronously (double flop)
            sync1 <= 1'b1;
            sync2 <= sync1;
        end
    end

    assign rst_n = sync2;

endmodule