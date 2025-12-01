module ring_osc(en, out);
    input en;
    logic n1;
    logic n2;
    output logic out;

    nand #5 A1(n1, en, out);
    not #5 N1(n2, n1);
    not #5 N2(out, n2);

endmodule