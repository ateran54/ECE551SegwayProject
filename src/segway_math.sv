module SegwayMath (
    input  logic               clk,
    input  logic               rst_n,
    input  logic  signed [11:0] PID_cntrl,
    input  logic         [7:0] ss_tmr,
    input  logic        [11:0] steer_pot,
    input  logic               en_steer,
    input  logic               pwr_up,
    output logic  signed [11:0] lft_spd,
    output logic  signed [11:0] rght_spd,
    output logic               too_fast
);

    //----------------------------------------------------------
    // Stage 1: Soft start multiply ONLY (combinational)
    // This is the expensive 8x12 multiply - isolate it
    //----------------------------------------------------------
    logic signed [19:0] PID_ss_unscaled;
    assign PID_ss_unscaled = $signed({1'b0,ss_tmr}) * PID_cntrl;

    //----------------------------------------------------------
    // Pipeline Stage A: Register multiply result immediately
    //----------------------------------------------------------
    logic signed [19:0] PID_ss_unscaled_pipe;
    logic [11:0] steer_pot_pipeA;
    logic en_steer_pipeA;
    logic pwr_up_pipeA;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            PID_ss_unscaled_pipe <= 20'sd0;
            steer_pot_pipeA <= 12'h000;
            en_steer_pipeA <= 1'b0;
            pwr_up_pipeA <= 1'b0;
        end else begin
            PID_ss_unscaled_pipe <= PID_ss_unscaled;
            steer_pot_pipeA <= steer_pot;
            en_steer_pipeA <= en_steer;
            pwr_up_pipeA <= pwr_up;
        end
    end

    //----------------------------------------------------------
    // Stage 2: Shift, steering saturation & offset (uses pipeA)
    //----------------------------------------------------------
    logic signed [11:0] PID_ss;
    assign PID_ss = PID_ss_unscaled_pipe >>> 8;  // Arithmetic right shift
    
    logic signed [12:0] PID_ss_sext;
    assign PID_ss_sext = $signed({PID_ss[11], PID_ss});

    // Steering pot saturation and offset
    logic [11:0] steer_pot_saturated;
    logic signed [11:0] steering_offset;
    assign steer_pot_saturated = steer_pot_pipeA < 12'h200 ? 12'h200 : 
                                  (steer_pot_pipeA > 12'hE00 ? 12'hE00 : steer_pot_pipeA);
    assign steering_offset = steer_pot_saturated - $signed(12'h7ff);

    // Scale by 3/16
    logic signed [11:0] steering_offset_scaled;
    assign steering_offset_scaled = {{3{steering_offset[11]}}, steering_offset[11:3]} + 
                                     {{4{steering_offset[11]}}, steering_offset[11:4]};

    // Calculate torques
    logic signed [12:0] lft_torque_steering;
    logic signed [12:0] lft_torque;
    assign lft_torque_steering = PID_ss_sext + $signed({steering_offset_scaled[11], steering_offset_scaled});
    assign lft_torque = en_steer_pipeA ? lft_torque_steering : PID_ss_sext;
    
    logic signed [12:0] rght_torque_steering;
    logic signed [12:0] rght_torque;
    assign rght_torque_steering = PID_ss_sext - $signed({steering_offset_scaled[11], steering_offset_scaled});
    assign rght_torque = en_steer_pipeA ? rght_torque_steering : PID_ss_sext;

    //----------------------------------------------------------
    // Pipeline Stage B: Register torques before deadzone shaping
    //----------------------------------------------------------
    logic signed [12:0] lft_torque_pipe;
    logic signed [12:0] rght_torque_pipe;
    logic pwr_up_pipeB;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            lft_torque_pipe <= 13'sd0;
            rght_torque_pipe <= 13'sd0;
            pwr_up_pipeB <= 1'b0;
        end else begin
            lft_torque_pipe <= lft_torque;
            rght_torque_pipe <= rght_torque;
            pwr_up_pipeB <= pwr_up_pipeA;
        end
    end

    //----------------------------------------------------------
    // Stage 3: Deadzone shaping (combinational, uses pipeB)
    //----------------------------------------------------------
    logic signed [12:0] lft_shaped;
    logic signed [12:0] rght_shaped;
    DeadzoneShaping deadzone_left(.torque_in(lft_torque_pipe), .pwr_up(pwr_up_pipeB), .torque_shaped(lft_shaped));
    DeadzoneShaping deadzone_right(.torque_in(rght_torque_pipe), .pwr_up(pwr_up_pipeB), .torque_shaped(rght_shaped));

    //----------------------------------------------------------
    // Pipeline Stage C: Register shaped outputs
    //----------------------------------------------------------
    logic signed [12:0] lft_shaped_pipe;
    logic signed [12:0] rght_shaped_pipe;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            lft_shaped_pipe <= 13'sd0;
            rght_shaped_pipe <= 13'sd0;
        end else begin
            lft_shaped_pipe <= lft_shaped;
            rght_shaped_pipe <= rght_shaped;
        end
    end

    //----------------------------------------------------------
    // Stage 4: Final saturation (simple, fast logic)
    //----------------------------------------------------------
    logic signed [11:0] lft_spd_comb;
    logic signed [11:0] rght_spd_comb;
    
    assign lft_spd_comb = lft_shaped_pipe[12] ? 
                (lft_shaped_pipe[11] ? lft_shaped_pipe[11:0] : 12'h800) : 
                (lft_shaped_pipe[11] ? 12'h7FF : lft_shaped_pipe[11:0]);

    assign rght_spd_comb = rght_shaped_pipe[12] ? 
                (rght_shaped_pipe[11] ? rght_shaped_pipe[11:0] : 12'h800) : 
                (rght_shaped_pipe[11] ? 12'h7FF : rght_shaped_pipe[11:0]);

    //----------------------------------------------------------
    // Pipeline Stage D: Register final outputs
    //----------------------------------------------------------
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            lft_spd <= 12'sd0;
            rght_spd <= 12'sd0;
            too_fast <= 1'b0;
        end else begin
            lft_spd <= lft_spd_comb;
            rght_spd <= rght_spd_comb;
            too_fast <= (lft_spd_comb > $signed(12'd1536)) || (rght_spd_comb > $signed(12'd1536));
        end
    end

endmodule

module DeadzoneShaping (
    input logic signed [12:0] torque_in,
    input logic pwr_up,
    output logic signed [12:0] torque_shaped
);

    localparam MIN_DUTY = 13'h0A8;
    localparam LOW_TORQUE_BAND = 7'h2A;
    localparam GAIN_MULT = 4'h4;

    //calcualte torque_comp
    logic signed [12:0] torque_comp;
    assign torque_comp = torque_in[12] ? (torque_in - $signed(MIN_DUTY)) : (torque_in + $signed(MIN_DUTY));
    
    logic signed [12:0] torque_comp_low_gain_band;
    assign torque_comp_low_gain_band = torque_in * $signed(GAIN_MULT);

    //compute low torque band output
    logic signed [12:0] torque_shaped_out;
    assign torque_shaped_out = $signed(GAIN_MULT) * torque_in;
    //compute abs value 
    logic [11:0] abs_torque_in;
    assign abs_torque_in = !torque_in[12] ? torque_in[11:0] : (~torque_in[11:0]+1);
    
    assign torque_shaped = !pwr_up ? 13'h0000 : (abs_torque_in > LOW_TORQUE_BAND ? torque_comp : torque_comp_low_gain_band);
endmodule   
