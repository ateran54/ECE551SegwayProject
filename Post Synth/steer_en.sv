module steer_en #(parameter fast_sim = 1)(
    input logic clk,
    input logic rst_n,
    input logic [11:0] lft_ld,
    input logic [11:0] rght_ld,
    output logic en_steer,
    output logic rider_off
);
    localparam MIN_RIDER_WT = 12'h200;
    localparam WT_HYSTERESIS = 8'h40;

    // Internal Signals
    logic [12:0] sum_13;
    logic signed [11:0] diff_12;
    logic [11:0] diff_12_abs;
    logic [12:0] sum_13_1516;
    logic [12:0] sum_13_14;
    logic [25:0] tmr;
    
    // Pipeline registers for multiplication results
    logic [12:0] sum_13_pipe;
    logic [11:0] diff_12_abs_pipe;
    logic [12:0] sum_13_1516_pipe;
    logic [12:0] sum_13_14_pipe;
    
    //state machine inputs
    logic tmr_full;
    logic sum_lt_min;
    logic sum_gt_min;
    logic diff_gt_1_4;
    logic diff_gt_15_16;

    //state machine outputs
    logic clr_tmr;

    // Stage 1: Basic arithmetic (combinational)
    assign sum_13 = lft_ld + rght_ld;
    assign diff_12 = $signed(lft_ld) - $signed(rght_ld);
    assign diff_12_abs = diff_12 < 0 ? (-1 * diff_12) : diff_12;
    
    // Pipeline the expensive operations
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            sum_13_pipe <= 13'h0000;
            diff_12_abs_pipe <= 12'h000;
            sum_13_1516_pipe <= 13'h0000;
            sum_13_14_pipe <= 13'h0000;
        end else begin
            sum_13_pipe <= sum_13;
            diff_12_abs_pipe <= diff_12_abs;
            sum_13_1516_pipe <= (sum_13 >> 4) * 15;  // Pipeline the multiply
            sum_13_14_pipe <= (sum_13 >> 2);
        end
    end

    //inputs to the state machine (using pipelined values)
    assign sum_lt_min = (MIN_RIDER_WT - WT_HYSTERESIS) > sum_13_pipe;
    assign sum_gt_min = (WT_HYSTERESIS + MIN_RIDER_WT) < sum_13_pipe;
    assign diff_gt_1_4 = (sum_13_14_pipe < diff_12_abs_pipe);
    assign diff_gt_15_16 = (sum_13_1516_pipe < diff_12_abs_pipe);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            tmr <= 0;
        end else if (clr_tmr) begin
            tmr <= 0;
        end else begin
            tmr <= tmr + 1;
        end
    end

    generate
        if (fast_sim)
            assign tmr_full = (&tmr[14:0]);
        else 
            assign tmr_full = (&tmr);
    endgenerate

      // state encoding
  typedef enum logic [1:0] {S_WAIT_FOR_RIDER, S_CHECK_STEADY, S_STEERING_ENABLED} state_t;

  state_t state, next_state;

  // state register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      state <= S_WAIT_FOR_RIDER;
    else 
      state <= next_state;
  end


  //state machine
  always_comb begin
    clr_tmr = 1'b0;
    en_steer = 1'b0;
    rider_off = 1'b0;
    next_state = state; // default stay in current state

    case (state)
      S_WAIT_FOR_RIDER: begin
        if (sum_gt_min) begin
          clr_tmr = 1'b1; // reset the timer
          next_state = S_CHECK_STEADY;
        end else begin
          rider_off = 1'b1; // indicate no rider present
        end
      end
      S_CHECK_STEADY: begin
        if (sum_lt_min) begin
          next_state = S_WAIT_FOR_RIDER;
          rider_off = 1'b1; // indicate no rider present
        end else if (diff_gt_1_4) begin
          clr_tmr = 1'b1; // reset the timer
        end else if (tmr_full) begin
          en_steer = 1'b1; // enable steering
          next_state = S_STEERING_ENABLED;
        end
      end
      S_STEERING_ENABLED: begin
        if (sum_lt_min) begin
          next_state = S_WAIT_FOR_RIDER;
          rider_off = 1'b1; // indicate no rider present
        end else if (diff_gt_15_16) begin
          clr_tmr = 1'b1; // reset the timer
          next_state = S_CHECK_STEADY;
        end else begin
          en_steer = 1'b1; // enable steering
        end
      end
      default: begin
        next_state = S_WAIT_FOR_RIDER; // should never happen
      end
    endcase
  end

endmodule