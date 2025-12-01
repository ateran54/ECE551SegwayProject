module up_dwn_cnt4 (
    input  logic clk,       // system clock
    input  logic rst_n,     // active-low reset
    input  logic en,        // enable counting
    input  logic dwn,       // 0 = count up, 1 = count down
    output logic [3:0] cnt  // 4-bit counter output
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'b0000;                  // reset to 0
        end else if (en) begin
            if (dwn)
                cnt <= cnt - 1'b1;           // count down
            else
                cnt <= cnt + 1'b1;           // count up
        end
    end

endmodule
