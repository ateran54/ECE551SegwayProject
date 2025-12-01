module SegwayMath(
    input  signed [11:0] PID_cntrl,   // Signed 12-bit control from PID
    input         [7:0]  ss_tmr,      // Unsigned 8-bit soft-start scaling
    input         [11:0] steer_pot,   // 12-bit unsigned steering pot measure
    input                en_steer,    // Steering enable signal
    input                pwr_up,      // Power up control signal
    output logic signed [11:0] lft_spd, // Left motor speed/torque (signed)
    output logic signed [11:0] rght_spd,// Right motor speed/torque (signed)
    output logic            too_fast    // Speed limit warning indicator
);

    // Local parameters
    localparam signed [12:0] MIN_DUTY        = 13'sd168;   // 0x0A8
    localparam signed [6:0]  LOW_TORQUE_BAND = 7'd42;      // 0x2A
    localparam signed [3:0]  GAIN_MULT       = 4'sd4;
    localparam signed [11:0] SPEED_LIMIT     = 12'sd1536;  // overspeed threshold

    // Internal signals
    logic signed [20:0] pid_scaled;
    logic signed [12:0] PID_ss;
    logic signed [12:0] steer_diff;
    logic signed [11:0] steer_scaled;
    logic signed [12:0] lft_torque, rght_torque;
    logic signed [12:0] lft_abs, rght_abs;
    logic signed [12:0] lft_shaped, rght_shaped;

    // PID soft-start scaling
    always_comb begin
        pid_scaled = PID_cntrl * $signed({1'b0, ss_tmr}); // 12-bit * 9-bit
        PID_ss     = pid_scaled >>> 8;
    end

    // Steering differential calculation
    always_comb begin

        steer_diff = $signed({1'b0, steer_pot}) - 13'sd2048;
        steer_scaled = (steer_diff * 3) >>> 4;
    end

    // Combine PID and steering
    always_comb begin
        if (en_steer && steer_diff != 0) begin
            lft_torque  = PID_ss + steer_scaled;
            rght_torque = PID_ss - steer_scaled;
        end else begin
            lft_torque  = PID_ss;
            rght_torque = PID_ss;
        end
    end

    // Absolute values for shaping
    always_comb begin
        lft_abs  = (lft_torque < 0)  ? -lft_torque  : lft_torque;
        rght_abs = (rght_torque < 0) ? -rght_torque : rght_torque;
    end

    // Torque shaping
    always_comb begin
        if (lft_abs < LOW_TORQUE_BAND)
            lft_shaped = lft_torque * GAIN_MULT;
        else
            lft_shaped = (lft_torque < 0) ? (lft_torque - MIN_DUTY) : (lft_torque + MIN_DUTY);

        if (rght_abs < LOW_TORQUE_BAND)
            rght_shaped = rght_torque * GAIN_MULT;
        else
            rght_shaped = (rght_torque < 0) ? (rght_torque - MIN_DUTY) : (rght_torque + MIN_DUTY);
    
        if (!pwr_up) begin
            lft_shaped  = 13'sd0;
            rght_shaped = 13'sd0;
        end

        if (lft_shaped > 13'sd2047)
            lft_spd = 12'sd2047;
        else if (lft_shaped < -13'sd2048)
            lft_spd = -12'sd2048;
        else
            lft_spd = lft_shaped[11:0];

        if (rght_shaped > 13'sd2047)
            rght_spd = 12'sd2047;
        else if (rght_shaped < -13'sd2048)
            rght_spd = -12'sd2048;
        else
            rght_spd = rght_shaped[11:0];
    end

    // Overspeed detection
    always_comb begin
        too_fast = (lft_spd > SPEED_LIMIT) || (lft_spd < -SPEED_LIMIT) ||
                   (rght_spd > SPEED_LIMIT) || (rght_spd < -SPEED_LIMIT);
    end

endmodule