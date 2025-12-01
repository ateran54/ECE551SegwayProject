module PB_release (
    input  logic clk,    // system clock
    input  logic PB,     // async push button input
    output logic released // 1-cycle pulse when button released
);

    logic q1, q2, q3;

    // First flop (async preset)
    always_ff @(posedge clk or posedge PB) begin
        if (PB)      // async preset when button not pressed
            q1 <= 1'b1;
        else
            q1 <= 1'b0;
    end

    // Second flop (async preset)
    always_ff @(posedge clk or posedge PB) begin
        if (PB)
            q2 <= 1'b1;
        else
            q2 <= q1;
    end

    // Third flop (async preset) for edge detection
    always_ff @(posedge clk or posedge PB) begin
        if (PB)
            q3 <= 1'b1;
        else
            q3 <= q2;
    end

    // Rising edge detect: q2 just went high while q3 still low
    assign released = q2 & ~q3;

endmodule
