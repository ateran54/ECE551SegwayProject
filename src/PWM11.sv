module PWM11 (
    input logic         clk,          // 50MHz system clock
    input logic         rst_n,        // Asynchronous active-low reset
    input logic [10:0]  duty,         // Unsigned 12-bit duty cycle (only 11 bits shown)

    output logic        PWM1,         // Complementary glitch-free PWM signal
    output logic        PWM2,         // Complementary glitch-free PWM signal (non-overlapping with PWM1)
    output logic        PWM_synch,    // Used to synchronize changes in duty
    output logic        ovr_I_blank   // Used to blank out overcurrent mitigation
);

    localparam NONOVERLAP = 11'h040;

    //cnt logic
    logic [10:0] cnt;
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            cnt <= 11'd0;
        else
            cnt <= cnt + 1;



    //combinational logic to set and reset flops 
    logic S_1;
    logic S_2;
    logic R_1;
    logic R_2;

    //THIS IS A FIX!
    assign S_1 = cnt >= NONOVERLAP;
    assign R_1 = cnt >= duty;

    assign S_2 = cnt >= (duty + NONOVERLAP);
    assign R_2 = &cnt;

    //S-R flops for PWM output
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            PWM1 <= 1'b0;
        else if (R_1)
            PWM1 <= 1'b0;
        else if (S_1)
            PWM1 <= 1'b1;
        
    
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            PWM2 <= 1'b0;
        else if (R_2)
            PWM2 <= 1'b0;
        else if (S_2)
            PWM2 <= 1'b1;


    assign PWM_synch = ~|cnt;
    assign ovr_I_blank = (cnt > NONOVERLAP + duty && cnt < NONOVERLAP + duty + 128) || (cnt < NONOVERLAP + 128 && cnt > NONOVERLAP);

endmodule
// module PWM11 (
//     input  logic        clk,        // 50MHz system clock
//     input  logic        rst_n,      // Asynchronous active-low reset
//     input  logic [10:0] duty,       // 11-bit unsigned duty cycle
//     output logic        PWM1,       // PWM output 1
//     output logic        PWM2,       // Complementary PWM output 2
//     output logic        PWM_synch,  // Synchronize duty updates
//     output logic        ovr_I_blank // Overcurrent blanking
// );

//     // Non-overlap parameter
//     localparam logic [10:0] NONOVERLAP = 11'h040;

//     // 11-bit counter
//     logic [10:0] cnt;

//     // Flip-flops for PWM1 and PWM2
//     logic pwm1_ff, pwm2_ff;

//     // Set/reset signals for PWM1 and PWM2
//     logic pwm1_set, pwm1_rst, pwm2_set, pwm2_rst;

//     // Counter logic
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             cnt <= 11'd0;
//         else
//             cnt <= cnt + 11'd1;
//     end

//     // Set/reset combinational logic for PWM1 and PWM2
//     assign pwm1_set = (cnt == NONOVERLAP) && (duty >= NONOVERLAP);
//     assign pwm1_rst = (cnt == (duty + NONOVERLAP)) && (duty >= NONOVERLAP);
//     assign pwm2_set = (cnt == (duty + NONOVERLAP)) && (duty >= NONOVERLAP);
//     assign pwm2_rst = (cnt == NONOVERLAP) && (duty >= NONOVERLAP);

    
//     // PWM1 flip-flop logic (set/reset)
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             pwm1_ff <= 1'b0;
//         else if (duty < NONOVERLAP)
//             pwm1_ff <= 1'b0;
//         else if (pwm1_set)
//             pwm1_ff <= 1'b1;
//         else if (pwm1_rst)
//             pwm1_ff <= 1'b0;
//     end

//     // PWM2 flip-flop logic (set/reset, complementary)
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n)
//             pwm2_ff <= 1'b1;
//         else if (duty < NONOVERLAP)
//             pwm2_ff <= 1'b1;
//         else if (pwm2_set)
//             pwm2_ff <= 1'b1;
//         else if (pwm2_rst)
//             pwm2_ff <= 1'b0;
//     end

//     assign PWM1 = pwm1_ff;
//     assign PWM2 = pwm2_ff;

//     // PWM_synch: high when counter is zero (start of PWM period)
//     assign PWM_synch = (cnt == 11'd0);

//     // Overcurrent blanking: high during first 128 cycles of PWM1 or PWM2
//     assign ovr_I_blank = 
//         ((cnt > NONOVERLAP) && (cnt < (NONOVERLAP + 11'd128))) ||
//         ((cnt > (duty + NONOVERLAP)) && (cnt < (duty + NONOVERLAP + 11'd128)));

// endmodule