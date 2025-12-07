module balance_cntrl #(parameter fast_sim = 1)(
    input logic clk,               // 50MHz system clock & active low reset
    input logic rst_n,             // Active low reset
    input logic vld,               // High when inertial sensor reading (pitch) is ready
    input logic [15:0] ptch,       // Pitch of Segway from inertial_intf
    input logic [15:0] ptch_rt,    // Pitch rate (degrees/sec) for D_term of PID
    input logic pwr_up,            // Segway balance control powered up
    input logic rider_off,         // Asserted when no rider detected
    input logic [11:0] steer_pot,  // From A2D_intf (steering potentiometer)
    input logic en_steer,          // Enables steering control
    output logic signed [11:0] PID_cntrl,  // PID control output
    output logic [7:0] ss_tmr,             // Soft start timer output
    output logic [11:0] lft_spd,   // 12-bit signed speed of left motor
    output logic [11:0] rght_spd,  // 12-bit signed speed of right motor
    output logic too_fast         // Rider approaching point of minimal control margin
);

    // Internal signals for PID calculations
    wire signed [12:0] error; 
    wire not_rdy;
    wire signed [11:0] frwrd;
    wire signed [13:0] pterm, iterm, dterm;
    reg signed [17:0] integrator;  // Essential integrator
    
    // Pipeline stage 1: Register PID terms
    reg signed [13:0] pterm_pipe, iterm_pipe, dterm_pipe;
    reg signed [11:0] frwrd_pipe;

    // Calculate PID terms
    assign error = {ptch[15],ptch[15:4]}; // Sign extend and divide by 16
    assign not_rdy = ~vld || ~pwr_up;
    assign frwrd = 12'h000; // No feedforward 
    assign pterm = {error[12],error} * $signed(5'h09); // P gain = 9
    assign dterm = {{2{ptch_rt[15]}},ptch_rt[15:4]}; // Sign extend D term

    // Pipeline stage 1: Register PID terms
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pterm_pipe <= 14'h0000;
            iterm_pipe <= 14'h0000;
            dterm_pipe <= 14'h0000;
            frwrd_pipe <= 12'h000;
        end else begin
            pterm_pipe <= pterm;
            iterm_pipe <= {{4{integrator[17]}},integrator[17:8]};
            dterm_pipe <= dterm;
            frwrd_pipe <= frwrd;
        end
    end

    // Integrator for I term
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            integrator <= 18'h00000;
        else if (rider_off)
            integrator <= 18'h00000;
        else if (!not_rdy)
            integrator <= integrator + {{5{error[12]}},error};
    end
    assign iterm = {{4{integrator[17]}},integrator[17:8]}; // I term from upper 10 bits

    // Pipeline stage 2: PID calculation with pipelined terms
    reg signed [12:0] PID_temp_pipe;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            PID_temp_pipe <= 13'h0000;
        end else begin
            PID_temp_pipe <= {pterm_pipe[13],pterm_pipe[13:2]} + {iterm_pipe[13],iterm_pipe[13:2]} + {dterm_pipe[13],dterm_pipe[13:2]} + {{1{frwrd_pipe[11]}},frwrd_pipe};
        end
    end
    
    // Saturation
    assign PID_cntrl = (PID_temp_pipe > 13'h07FF) ? 12'h7FF :
                       (PID_temp_pipe < 13'h1800) ? 12'h800 : PID_temp_pipe[11:0];
    
    // Simple soft start timer
    reg [7:0] ss_counter;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            ss_counter <= 8'h00;
        else if (pwr_up && ~&ss_counter)
            ss_counter <= ss_counter + 1'b1;
    end
    assign ss_tmr = ss_counter;
    
    // Simple motor speed calculations with pipelining
    wire signed [19:0] ss_mult;
    wire signed [11:0] pid_ss;
    wire signed [12:0] steer_offset;
    wire signed [11:0] steer_scaled;
    wire signed [12:0] lft_torque, rght_torque;
    
    // Pipeline stage 3: Motor calculations
    reg signed [11:0] pid_ss_pipe;
    reg signed [11:0] steer_scaled_pipe;
    reg en_steer_pipe;
    
    // Soft start multiply
    assign ss_mult = PID_cntrl * $signed({1'b0,ss_tmr});
    assign pid_ss = ss_mult[19:8];
    
    // Steering calculation  
    assign steer_offset = $signed({1'b0,steer_pot}) - $signed(13'h800);
    assign steer_scaled = steer_offset[12:1]; // Divide by 2
    
    // Pipeline stage 3
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pid_ss_pipe <= 12'h000;
            steer_scaled_pipe <= 12'h000;
            en_steer_pipe <= 1'b0;
        end else begin
            pid_ss_pipe <= pid_ss;
            steer_scaled_pipe <= steer_scaled;
            en_steer_pipe <= en_steer;
        end
    end
    
    // Calculate motor torques with pipelined inputs
    assign lft_torque = en_steer_pipe ? (pid_ss_pipe - steer_scaled_pipe) : pid_ss_pipe;
    assign rght_torque = en_steer_pipe ? (pid_ss_pipe + steer_scaled_pipe) : pid_ss_pipe;
    
    // Simple speed assignment with deadzone
    assign lft_spd = (lft_torque[12]) ? ((lft_torque > -13'h200) ? 12'h000 : -lft_torque[11:0]) :
                     ((lft_torque < 13'h200) ? 12'h000 : lft_torque[11:0]);
    assign rght_spd = (rght_torque[12]) ? ((rght_torque > -13'h200) ? 12'h000 : -rght_torque[11:0]) :
                      ((rght_torque < 13'h200) ? 12'h000 : rght_torque[11:0]);
                      
    assign too_fast = (lft_spd > 12'd1536) || (rght_spd > 12'd1536);
endmodule
