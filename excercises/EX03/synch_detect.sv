module synch_detect(asynch_sig_in, clk, rst_n, rise_edge);
    input asynch_sig_in;
    input clk;
    input rst_n;
    output logic rise_edge;

    logic FF1,FF2,FF3;
    //Two flip-flops for meta stability
    dff dff1(.D(asynch_sig_in), .clk(clk), .PRN(rst_n), .Q(FF1));
    dff dff2(.D(FF1), .clk(clk), .PRN(rst_n), .Q(FF2));
    //Flop to detect rising edge
    dff dff3(.D(FF2), .clk(clk), .PRN(rst_n), .Q(FF3));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rise_edge <= 1'b0;
        end else begin
            FF1 <= asynch_sig_in;
            FF2 <= FF1;
            FF3 <= FF2;
        end
        assign rise_edge = (FF2 && ~FF3) ? 1'b1 : 1'b0;
    end

endmodule