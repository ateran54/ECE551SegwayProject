module MSFF (
    input clk,
    input d,
    output q
);
    wire md;
    wire mq;
    wire sd;
    wire clk_n;

    not (clk_n, clk);
    notif1 (md, d, clk_n);
    not (mq, md);
    not (weak0, weak1) inv1(md, mq);

    notif1 (sd, mq, clk);
    not (q, sd);
    not (weak0, weak1) inv2(sd, q);

endmodule