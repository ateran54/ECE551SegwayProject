// `timescale 1ns/1ps

// module a2d_intf_tb;

//     // Clock and reset
//     logic clk;
//     logic rst_n;
//     logic nxt;

//     // Outputs from A2D_intf
//     logic [11:0] lft_ld;
//     logic [11:0] rght_ld;
//     logic [11:0] steer_pot;
//     logic [11:0] batt;

//     // SPI signals
//     logic SS_n, SCLK, MOSI, MISO;

//     // ================
//     // Clock generation
//     // ================
//     initial begin
//         clk = 0;
//         forever #10 clk = ~clk;     // 50 MHz clock (20 ns period)
//     end

//     // ==============================
//     // Instantiate DUT (your module)
//     // ==============================
//     a2d_intf DUT (
//         .clk(clk),
//         .rst_n(rst_n),
//         .nxt(nxt),
//         .lft_ld(lft_ld),
//         .rght_ld(rght_ld),
//         .steer_pot(steer_pot),
//         .batt(batt),
//         .SS_n(SS_n),
//         .SCLK(SCLK),
//         .MOSI(MOSI),
//         .MISO(MISO)
//     );


//     // SPI Transaction helper


//     // =====================================
//     // Instantiate ADC128S device model
//     // =====================================
//     ADC128S adc_model (
//         .clk(clk),
//         .rst_n(rst_n),
//         .SS_n(SS_n),
//         .SCLK(SCLK),
//         .MISO(MISO),
//         .MOSI(MOSI)
//     );

//     task automatic read_a2d();
//         begin : read_a2d
//             fork 
//                 begin
//                     @(posedge clk);
//                     #1;
//                     nxt = 1;
//                     @(posedge clk);
//                     #1;
//                     nxt = 0;
//                     #100;
//                     disable read_a2d;
//                 end

//                 begin
//                     repeat(10000000) @(posedge clk);
//                     $display("ERROR: WAITING FOR SM TIMED OUT!");
//                     $stop;
//                 end
//             join
//         end
//     endtask

//     // ======================
//     // Testbench main process
//     // ======================
//     initial begin
//         $display("\n===== Starting A2D Interface Testbench =====");

//         // Reset sequence
//         rst_n = 0;
//         nxt   = 0;
//         repeat (10) @(posedge clk);
//         rst_n = 1;
//         repeat (10) @(posedge clk);

//         // ===========================
//         // Perform several A2D samples
//         // ===========================
//         read_a2d();
//         read_a2d();
//         read_a2d();
//         read_a2d();

//         // Wait long enough for 2 SPI cycles per nxt
//         //repeat (1000) @(posedge clk);

//         $display("Round Robin Values:");
//         $display("  lft_ld     = %h", lft_ld);
//         $display("  rght_ld    = %h", rght_ld);
//         $display("  steer_pot  = %h", steer_pot);
//         $display("  batt       = %h", batt);

//         // ============================
//         // Finish simulation
//         // ============================
//         $display("\n===== A2D Testbench Complete =====");
//         $stop;
//     end

// endmodule
`timescale 1ns/1ps

module a2d_intf_tb;

    // Clock and reset
    logic clk;
    logic rst_n;
    logic nxt;

    // Outputs from A2D_intf
    logic [11:0] lft_ld;
    logic [11:0] rght_ld;
    logic [11:0] steer_pot;
    logic [11:0] batt;

    // SPI signals
    logic SS_n, SCLK, MOSI, MISO;

    // ================
    // Clock generation
    // ================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;     // 50 MHz clock (20 ns period)
    end

    // ==============================
    // Instantiate DUT (your module)
    // ==============================
    a2d_intf DUT (
        .clk(clk),
        .rst_n(rst_n),
        .nxt(nxt),
        .lft_ld(lft_ld),
        .rght_ld(rght_ld),
        .steer_pot(steer_pot),
        .batt(batt),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    // =====================================
    // Instantiate ADC128S device model
    // =====================================
    ADC128S adc_model (
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI)
    );

    // ======================
    // Testbench main process
    // ======================
    initial begin
        $display("\n===== Starting A2D Interface Testbench =====");

        // Reset sequence
        rst_n = 0;
        nxt   = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        // ===========================
        // Perform several A2D samples
        // ===========================
        repeat (8) begin
            @(posedge clk);
            nxt = 1;
            @(posedge clk);
            nxt = 0;

            // Wait long enough for 2 SPI cycles per nxt
            repeat (1000) @(posedge clk);

            $display("Round Robin Values:");
            $display("  lft_ld     = %h", lft_ld);
            $display("  rght_ld    = %h", rght_ld);
            $display("  steer_pot  = %h", steer_pot);
            $display("  batt       = %h", batt);
        end

        // ============================
        // Finish simulation
        // ============================
        $display("\n===== A2D Testbench Complete =====");
        $stop;
    end

endmodule
