module rst_synch (
    input logic RST_n,
    input logic clk,
    output logic rst_n
);
    logic rst_n_inter;
    always_ff @(negedge clk, negedge RST_n) begin
        if (!RST_n)
            rst_n_inter <= 0;
        else
            rst_n_inter <= 1;
    end

    always_ff @(negedge clk, negedge RST_n) begin
        if (!RST_n)
            rst_n <= 0;
        else
            rst_n <= rst_n_inter;
    end


endmodule
