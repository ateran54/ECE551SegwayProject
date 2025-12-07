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
    // Direct computation: Soft start multiply and processing
    //----------------------------------------------------------
    logic signed [19:0] PID_ss_unscaled;
    assign PID_ss_unscaled = $signed({1'b0,ss_tmr}) * PID_cntrl;
    
    logic signed [11:0] PID_ss;
    assign PID_ss = PID_ss_unscaled >>> 8;  // Arithmetic right shift
    
    logic signed [12:0] PID_ss_sext;
    assign PID_ss_sext = $signed({PID_ss[11], PID_ss});

    // Steering calculations
    logic [11:0] steer_pot_saturated;
    logic signed [11:0] steering_offset;
    assign steer_pot_saturated = steer_pot < 12'h200 ? 12'h200 : 
                                 (steer_pot > 12'hE00 ? 12'hE00 : steer_pot);
    assign steering_offset = steer_pot_saturated - $signed(12'h7ff);

    // Scale by 3/16 (simplified)
    logic signed [11:0] steering_offset_scaled;
    assign steering_offset_scaled = {{3{steering_offset[11]}}, steering_offset[11:3]} + 
                                     {{4{steering_offset[11]}}, steering_offset[11:4]};

    // Calculate torques directly
    logic signed [12:0] lft_torque_steering;
    logic signed [12:0] lft_torque;
    assign lft_torque_steering = PID_ss_sext + $signed({steering_offset_scaled[11], steering_offset_scaled});
    assign lft_torque = en_steer ? lft_torque_steering : PID_ss_sext;
    
    logic signed [12:0] rght_torque_steering;
    logic signed [12:0] rght_torque;
    assign rght_torque_steering = PID_ss_sext - $signed({steering_offset_scaled[11], steering_offset_scaled});
    assign rght_torque = en_steer ? rght_torque_steering : PID_ss_sext;

    //----------------------------------------------------------
    // Deadzone shaping (combinational)
    //----------------------------------------------------------
    logic signed [12:0] lft_shaped;
    logic signed [12:0] rght_shaped;
    DeadzoneShaping deadzone_left(.torque_in(lft_torque), .pwr_up(pwr_up), .torque_shaped(lft_shaped));
    DeadzoneShaping deadzone_right(.torque_in(rght_torque), .pwr_up(pwr_up), .torque_shaped(rght_shaped));

    //----------------------------------------------------------
    // Final stage: Direct saturation and output 
    //----------------------------------------------------------
    assign lft_spd = lft_shaped[12] ? 
                (lft_shaped[11] ? lft_shaped[11:0] : 12'h800) : 
                (lft_shaped[11] ? 12'h7FF : lft_shaped[11:0]);

    assign rght_spd = rght_shaped[12] ? 
                (rght_shaped[11] ? rght_shaped[11:0] : 12'h800) : 
                (rght_shaped[11] ? 12'h7FF : rght_shaped[11:0]);

    assign too_fast = (lft_spd > $signed(12'd1536)) || (rght_spd > $signed(12'd1536));

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
