module piezo_drv #(parameter fast_sim = 1) (
    input clk,
    input rst_n,
    input en_steer,
    input too_fast,
    input batt_low,
    output reg piezo,
    output piezo_n
);

// Assign piezo_n as complement of piezo for differential drive
assign piezo_n = ~piezo;

// Note frequencies (in clock cycles for 50MHz clock)
// These are half-periods for 50% duty cycle
localparam G6_HALF_PERIOD = 15943;  // 50MHz / (2 * 1568Hz)
localparam C7_HALF_PERIOD = 11945;  // 50MHz / (2 * 2093Hz)
localparam E7_HALF_PERIOD = 9485;   // 50MHz / (2 * 2637Hz)
localparam G7_HALF_PERIOD = 7969;   // 50MHz / (2 * 3136Hz)

// Note durations (in clock cycles)
localparam NOTE_DUR_223 = 223;
localparam NOTE_DUR_222 = 222;
localparam NOTE_DUR_225 = 225;

// 3 second timer (150M clock cycles at 50MHz)
localparam THREE_SEC = 150000000;

// Generate increment value based on fast_sim parameter
generate
    if (fast_sim) begin : fast_sim_gen
        localparam INCREMENT = 64;
    end else begin : normal_sim_gen
        localparam INCREMENT = 1;
    end
endgenerate

// Wire to access the increment value
wire [6:0] increment_val = fast_sim ? 64 : 1;

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

state_t current_state, next_state;

// Counters
reg [31:0] duration_counter;
reg [31:0] repeat_counter;
reg [15:0] period_counter;
reg [31:0] current_duration;
reg [15:0] current_half_period;

// Control signals
reg note_done = 1'b1;
reg repeat_done = 1'b1; // Start as done to allow immediate first play
reg freq_toggle;
reg playing_backwards;
reg start_tmr = 1'b0;
reg prev_idle_state = 1'b1;
reg first_sequence_done = 1'b0; // Track if we've completed the first sequence

// Duration counter - tracks how long current note has been playing
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        duration_counter <= 0;
        note_done <= 0;
    end else begin
        if (current_state == IDLE) begin
            duration_counter <= 0;
            note_done <= 0;
        end else begin
            if (duration_counter >= current_duration - 1) begin
                duration_counter <= 0;
                note_done <= 1;
            end else begin
                duration_counter <= duration_counter + increment_val;
                note_done <= 0;
            end
        end
    end
end

// Repeat timer - 3 second timer for repeating charge fanfare
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        repeat_counter <= 0;
        repeat_done <= 1'b1; // Start as done to allow immediate first play
        start_tmr <= 1'b0;
        first_sequence_done <= 1'b0;
    end else begin
        // Detect when a FORWARD sequence finishes (transition from G7_NOTE2 to IDLE)
        if (current_state == G7_NOTE2 && note_done && !too_fast && !playing_backwards) begin
            // Forward sequence just finished - start the 3-second timer
            start_tmr <= 1'b1;
            repeat_counter <= 0;
            repeat_done <= 1'b0; // Block next sequence until timer expires
            first_sequence_done <= 1'b1; // Mark that we've had at least one sequence
        end
        // Detect when a BACKWARDS sequence finishes (transition from G6_NOTE to IDLE when playing backwards)
        else if (current_state == G6_NOTE && note_done && !too_fast && playing_backwards) begin
            // Backwards sequence just finished - start the 3-second timer
            start_tmr <= 1'b1;
            repeat_counter <= 0;
            repeat_done <= 1'b0; // Block next sequence until timer expires
            first_sequence_done <= 1'b1; // Mark that we've had at least one sequence
        end
        // Count the 3-second delay
        else if (start_tmr && !repeat_done) begin
            if (repeat_counter >= (THREE_SEC / increment_val) - 1) begin
                repeat_done <= 1'b1; // Timer expired - allow next sequence
                start_tmr <= 1'b0;
            end else begin
                repeat_counter <= repeat_counter + increment_val;
            end
        end
        
        // Track previous IDLE state
        prev_idle_state <= (current_state == IDLE);
    end
end

// Period timer - generates the frequency for each note
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        period_counter <= 0;
        freq_toggle <= 0;
    end else begin
        if (current_state == IDLE) begin
            period_counter <= 0;
            freq_toggle <= 0;
        end else begin
            if (period_counter >= (current_half_period / increment_val) - 1) begin
                period_counter <= 0;
                freq_toggle <= 1;
            end else begin
                period_counter <= period_counter + 1;
                freq_toggle <= 0;
            end
        end
    end
end

// Piezo output generation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        piezo <= 0;
    end else begin
        if (current_state == IDLE) begin
            piezo <= 0;
        end else if (freq_toggle) begin
            piezo <= ~piezo;
        end
    end
end

// State machine - next state logic
always_comb begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (too_fast) begin
                // too_fast has highest priority - play first 3 notes continuously
                next_state = G6_NOTE;
            end else if (batt_low && repeat_done) begin
                // batt_low plays charge backwards, but only if 3-second timer is done
                playing_backwards = 1;
                next_state = G7_NOTE2;
            end else if (en_steer && repeat_done) begin
                // Normal charge fanfare, but only if 3-second timer is done
                playing_backwards = 0;
                next_state = G6_NOTE;
            end
        end
        
        G6_NOTE: begin
            if (note_done) begin
                if (too_fast) begin
                    // For too_fast, only play first 3 notes, then loop
                    next_state = C7_NOTE;
                end else if (playing_backwards) begin
                    next_state = IDLE;
                end else begin
                    next_state = C7_NOTE;
                end
            end
        end
        
        C7_NOTE: begin
            if (note_done) begin
                if (too_fast) begin
                    next_state = E7_NOTE1;
                end else if (playing_backwards) begin
                    next_state = G6_NOTE;
                end else begin
                    next_state = E7_NOTE1;
                end
            end
        end
        
        E7_NOTE1: begin
            if (note_done) begin
                if (too_fast) begin
                    // Loop back to beginning for continuous play of first 3 notes
                    next_state = G6_NOTE;
                end else if (playing_backwards) begin
                    next_state = C7_NOTE;
                end else begin
                    next_state = G7_NOTE1;
                end
            end
        end
        
        G7_NOTE1: begin
            if (note_done) begin
                if (playing_backwards) begin
                    next_state = E7_NOTE1;
                end else begin
                    next_state = E7_NOTE2;
                end
            end
        end
        
        E7_NOTE2: begin
            if (note_done) begin
                if (playing_backwards) begin
                    next_state = G7_NOTE1;
                end else begin
                    next_state = G7_NOTE2;
                end
            end
        end
        
        G7_NOTE2: begin
            if (note_done) begin
                if (playing_backwards) begin
                    next_state = E7_NOTE2;
                end else if (too_fast) begin
                    next_state = G6_NOTE;
                end else begin
                    // Normal completion - always go back to IDLE
                    // Timer will be reset when next sequence starts
                    next_state = IDLE;
                end
            end
        end
        default: next_state = IDLE;
    endcase
    
    // Override for priority conditions
    if (too_fast && current_state != IDLE) begin
        // too_fast has priority over everything - let current note finish then force to appropriate next note
        if (note_done) begin
            if (current_state == G6_NOTE) begin
                next_state = C7_NOTE; // G6 -> C7 in too_fast mode
            end else if (current_state == C7_NOTE) begin
                next_state = E7_NOTE1; // C7 -> E7 in too_fast mode
            end else if (current_state == E7_NOTE1) begin
                next_state = G6_NOTE; // E7 -> G6 to loop back in too_fast mode
            end else begin
                // If in any other state when too_fast asserted, go to first note
                next_state = G6_NOTE;
            end
        end
    end
end

// State machine - state register
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Set current note parameters based on state
always_comb begin
    case (current_state)
        G6_NOTE: begin
            current_half_period = G6_HALF_PERIOD;
            current_duration = NOTE_DUR_223;
        end
        C7_NOTE: begin
            current_half_period = C7_HALF_PERIOD;
            current_duration = NOTE_DUR_223;
        end
        E7_NOTE1: begin
            current_half_period = E7_HALF_PERIOD;
            current_duration = NOTE_DUR_223;
        end
        G7_NOTE1: begin
            current_half_period = G7_HALF_PERIOD;
            current_duration = NOTE_DUR_223 + NOTE_DUR_222; // 445 clocks total
        end
        E7_NOTE2: begin
            current_half_period = E7_HALF_PERIOD;
            current_duration = NOTE_DUR_222;
        end
        G7_NOTE2: begin
            current_half_period = G7_HALF_PERIOD;
            current_duration = NOTE_DUR_225;
        end
        default: begin
            current_half_period = G6_HALF_PERIOD;
            current_duration = NOTE_DUR_223;
        end
    endcase
end

endmodule
