module saturate_tb;

    // Testbench signals
    reg  [15:0] unsigned_err;
    wire [9:0]  unsigned_err_sat;
    reg  [15:0] signed_err;
    wire [9:0]  signed_err_sat;
    reg  [9:0]  signed_D_diff;
    wire [6:0]  signed_D_diff_sat;

    // Instantiate the DUT
    saturate dut (
        .unsigned_err(unsigned_err),
        .unsigned_err_sat(unsigned_err_sat),
        .signed_err(signed_err),
        .signed_err_sat(signed_err_sat),
        .signed_D_diff(signed_D_diff),
        .signed_D_diff_sat(signed_D_diff_sat)
    );

    // Reference model
    function [9:0] ref_unsigned_err_sat(input [15:0] val);
        ref_unsigned_err_sat = (|val[15:10]) ? 10'h3FF : val[9:0];
    endfunction

    function [9:0] ref_signed_err_sat(input [15:0] val);
        ref_signed_err_sat = ((&val[15]) && (~&val[14:9])) ? 10'h200 :
                             ((~&val[15]) && (&val[14:9])) ? 10'h1FF : val[9:0];
    endfunction

    function [6:0] ref_signed_D_diff_sat(input [9:0] val);
        ref_signed_D_diff_sat = ((&val[9]) && (~&val[8:6])) ? 7'h40 :
                                ((~&val[9]) && (&val[8:6])) ? 7'h3F : val[6:0];
    endfunction

    // Test procedure
    initial begin
        integer i;
        reg [9:0] expected_unsigned;
        reg [9:0] expected_signed;
        reg [6:0] expected_D_diff;
        reg error;

        error = 0;

        unsigned_err = 16'h1000;
            #1;
            expected_unsigned = 10'h3FF;
            if (unsigned_err_sat !== expected_unsigned) begin
                $display("FAIL unsigned_err: in=%h out=%h exp=%h", unsigned_err, unsigned_err_sat, expected_unsigned);
                error = 1;
            end
        // Test unsigned_err
        for (i = 0; i < 20; i = i + 1) begin
            unsigned_err = $random;
            #1;
            expected_unsigned = ref_unsigned_err_sat(unsigned_err);
            if (unsigned_err_sat !== expected_unsigned) begin
                $display("FAIL unsigned_err: in=%h out=%h exp=%h", unsigned_err, unsigned_err_sat, expected_unsigned);
                error = 1;
            end
        end

         signed_err = 16'h8000; ;
            #1;
            expected_signed = 10'h200;
            if (signed_err_sat !== expected_signed) begin
                $display("FAIL signed_err: in=%h out=%h exp=%h", signed_err, signed_err_sat, expected_signed);
                error = 1;
            end

         signed_err = 16'h7FFF;
            #1;
            expected_signed = 10'h1FF;
            if (signed_err_sat !== expected_signed) begin
                $display("FAIL signed_err: in=%h out=%h exp=%h", signed_err, signed_err_sat, expected_signed);
                error = 1;
            end
         signed_err = 16'h0002;
            #1;
            expected_signed = 10'h002;
            if (signed_err_sat !== expected_signed) begin
                $display("FAIL signed_err: in=%h out=%h exp=%h", signed_err, signed_err_sat, expected_signed);
                error = 1;
            end    
        // Test signed_err
        for (i = 0; i < 20; i = i + 1) begin
            signed_err = $random;
            #1;
            expected_signed = ref_signed_err_sat(signed_err);
            if (signed_err_sat !== expected_signed) begin
                $display("FAIL signed_err: in=%h out=%h exp=%h", signed_err, signed_err_sat, expected_signed);
                error = 1;
            end
        end

            signed_D_diff = 10'h200;
            #1;
            expected_D_diff = 7'h40;
            if (signed_D_diff_sat !== expected_D_diff) begin
                $display("FAIL signed_D_diff: in=%h out=%h exp=%h", signed_D_diff, signed_D_diff_sat, expected_D_diff);
                error = 1;
            end
            signed_D_diff = 10'h1FF;
            #1;
            expected_D_diff = 7'h3F;
            if (signed_D_diff_sat !== expected_D_diff) begin
                $display("FAIL signed_D_diff: in=%h out=%h exp=%h", signed_D_diff, signed_D_diff_sat, expected_D_diff);
                error = 1;
            end
            signed_D_diff = 10'h002;
            #1;
            expected_D_diff = 7'h02;
            if (signed_D_diff_sat !== expected_D_diff) begin
                $display("FAIL signed_D_diff: in=%h out=%h exp=%h", signed_D_diff, signed_D_diff_sat, expected_D_diff);
                error = 1;
            end
        // Test signed_D_diff
        for (i = 0; i < 20; i = i + 1) begin
            signed_D_diff = $random;
            #1;
            expected_D_diff = ref_signed_D_diff_sat(signed_D_diff);
            if (signed_D_diff_sat !== expected_D_diff) begin
                $display("FAIL signed_D_diff: in=%h out=%h exp=%h", signed_D_diff, signed_D_diff_sat, expected_D_diff);
                error = 1;
            end
        end

        if (!error)
            $display("All tests passed!");
        $finish;
    end

endmodule