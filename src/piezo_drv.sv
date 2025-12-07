module piezo_drv #(parameter fast_sim = 1) (
    input logic clk,
    input logic rst_n,
    input logic en_steer,
    input logic too_fast,
    input logic batt_low,
    output logic piezo,
    output logic piezo_n
);

// Note frequencies (in clock cycles for 50MHz clock)
// These are half-periods for 50% duty cycle
localparam G6_HALF_PERIOD = fast_sim ? 15943 >> 6 : 15943;  // 50MHz / (2 * 1568Hz)
localparam C7_HALF_PERIOD = fast_sim ? 11945 >> 6 : 11945;  // 50MHz / (2 * 2093Hz)
localparam E7_HALF_PERIOD = fast_sim ? 9485 >> 6 : 9485;   // 50MHz / (2 * 2637Hz)
localparam G7_HALF_PERIOD = fast_sim ? 7969 >> 6 : 7969;   // 50MHz / (2 * 3136Hz)

// Note durations (in clock cycles)
localparam NOTE_DUR_223 = 1 << 23;
localparam NOTE_DUR_222 = 1 << 22;
localparam NOTE_DUR_225 = 1 << 25;

// 3 second timer (150M clock cycles at 50MHz)
localparam THREE_SEC = 150000000;

// Generate increment value based on fast_sim parameter
logic [6:0] increment_val = fast_sim ? 64 : 1;


// State machine states
typedef enum logic [3:0] {
    IDLE,
    G6_NOTE,
    C7_NOTE,
    E7_NOTE1,
    G7_NOTE1,
    E7_NOTE2,
    G7_NOTE2
} state_t;



// Duration timer - measures duration for each note
logic [31:0] duration_timer;
logic clr_dur_tmr;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        duration_timer <= 0;
    end else if (clr_dur_tmr) begin
        duration_timer <= 0;
    end else begin
        duration_timer <= duration_timer + increment_val;
    end
end
// Repeat Timer
logic signed [31:0] repeat_timer;
logic repeat_tmr_done;
logic start_repeat_tmr;
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        repeat_timer <= 0;
    end else if (start_repeat_tmr) begin
        repeat_timer <= 32'h0x08F0D180;
    end else begin
        if (repeat_timer > 0) begin
            repeat_timer <= (repeat_timer - increment_val >= 0 ? repeat_timer - increment_val : 0);
        end
    end
end

assign repeat_tmr_done = (repeat_timer == 0);

// Frequency timer + Differential output geneneration
logic [31:0] period_counter;
logic [15:0] current_period;
logic clr_freq_tmr;
logic toggle;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        period_counter <= 0;
    end else if (clr_freq_tmr) begin
        period_counter <= 0;
        toggle <= 0;
    end else if (period_counter >= current_period) begin
        toggle <= 1;
        period_counter <= 0;
    end else begin
        period_counter <= period_counter + 1; // Speed up for simulation
        toggle <= 0;
    end
end

//Differential Piezo Output 
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        piezo <= 0;
        piezo_n <= 0;
    end else if (toggle) begin
            piezo <= ~piezo;
            piezo_n <= piezo;
    end
end


state_t current_state, next_state;

always_comb begin

    //State machine outputs
    start_repeat_tmr = 0;
    clr_dur_tmr = 0;
    next_state = current_state;
    current_period = 0;
    case (current_state)
        IDLE: begin 
            if (too_fast) begin 
                next_state = G6_NOTE;
                start_repeat_tmr = 1;//In case if too fast gts deasserted mid way
            end else if (repeat_tmr_done) begin
                if (batt_low) begin
                    start_repeat_tmr = 1;
                    clr_dur_tmr = 1;
                    next_state = G7_NOTE2;
                end else if (en_steer) begin
                    start_repeat_tmr = 1;
                    clr_dur_tmr = 1;
                    next_state = G6_NOTE;
                end
            end         
        end

        G6_NOTE: begin
            current_period = G6_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_223) begin
                clr_dur_tmr = 1;
                if (too_fast) begin
                    next_state = C7_NOTE;
                end else if (batt_low) begin
                    next_state = IDLE;
                end else begin
                    next_state = C7_NOTE;
                end
            end        
        end

        C7_NOTE: begin
            current_period = C7_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_223) begin
                clr_dur_tmr = 1;
                if (too_fast) begin
                    next_state = E7_NOTE1;
                end else if (batt_low) begin
                    next_state = G6_NOTE;
                end else begin
                    next_state = E7_NOTE1;
                end
            end        
        end
        E7_NOTE1: begin
            current_period = E7_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_223) begin
                clr_dur_tmr = 1;
                if (too_fast) begin
                    next_state = G6_NOTE;
                end else if (batt_low) begin
                    next_state = C7_NOTE;
                end else begin
                    next_state = G7_NOTE1;
                end
            end    
        end
        G7_NOTE1: begin
            current_period = G7_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_223 + NOTE_DUR_222) begin
                clr_dur_tmr = 1;
                if (batt_low) begin
                    next_state = E7_NOTE1;
                end else begin
                    next_state = E7_NOTE2;
                end
            end    // 445 clocks total
        end
        E7_NOTE2: begin
            current_period = E7_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_222) begin
                clr_dur_tmr = 1;
                if (batt_low) begin
                    next_state = G7_NOTE1;
                end else begin
                    next_state = G7_NOTE2;
                end
            end  
        end
        G7_NOTE2: begin
            current_period = G7_HALF_PERIOD;
            if (duration_timer >= NOTE_DUR_225) begin
                clr_dur_tmr = 1;
                if (batt_low) begin
                    next_state = E7_NOTE2;
                end else begin
                    next_state = IDLE;
                end
            end
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

// State machine - state register
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

endmodule