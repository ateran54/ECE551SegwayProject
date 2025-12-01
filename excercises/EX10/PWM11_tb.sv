
module PWM11_tb;
    // Parameters
    localparam CLK_PERIOD = 20; // 50MHz = 20ns period

    // Testbench signals
    logic clk;
    logic rst_n;
    logic [10:0] duty;
    logic PWM1, PWM2, PWM_synch, ovr_I_blank;

    // Instantiate DUT
    PWM11 dut (
        .clk(clk),
        .rst_n(rst_n),
        .duty(duty),
        .PWM1(PWM1),
        .PWM2(PWM2),
        .PWM_synch(PWM_synch),
        .ovr_I_blank(ovr_I_blank)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Stimulus
    initial begin
        // Initialize
        rst_n = 0;
        duty = 11'd0;
        #(5*CLK_PERIOD);
        rst_n = 1;

        // Test various duty cycles
        repeat (2) @(posedge PWM_synch); // Wait for sync
        duty = 11'd0;      // 0% duty
        repeat (2) @(posedge PWM_synch);
        duty = 11'd64;     // NONOVERLAP (should be 0% output)
        repeat (2) @(posedge PWM_synch);
        duty = 11'd128;    // Small duty
        repeat (2) @(posedge PWM_synch);
        duty = 11'd512;    // ~25% duty
        repeat (2) @(posedge PWM_synch);
        duty = 11'd1024;   // ~50% duty
        repeat (2) @(posedge PWM_synch);
        duty = 11'd1536;   // ~75% duty
        repeat (2) @(posedge PWM_synch);
        duty = 11'd1984;   // Near max
        repeat (2) @(posedge PWM_synch);
        duty = 11'd2047;   // Max
        repeat (2) @(posedge PWM_synch);
        $stop;
    end

endmodule
