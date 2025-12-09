module UART_tx (
    input logic clk,         // 50MHz system clock
    input logic rst_n,       // Active low reset
    input logic trmt,        // Asserted for 1 clock to initiate transmission
    input logic [7:0] tx_data,     // Byte to transmit
    output logic TX,          // Serial data output
    output logic tx_done      // Asserted when byte is done transmitting
);

// Internal logic goes here
typedef enum {IDLE, TRANSMITTING} state_t;
state_t cur_state;
state_t nxt_state;

//internal signals
logic load;
logic shift;
logic transmitting;

//serial data register logic 
logic [8:0] tx_shft_reg;
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        tx_shft_reg <= 9'h1FF;
    else if (load)
        tx_shft_reg <= {tx_data, 1'b0};
    else if (shift)
        tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};
end

assign TX = tx_shft_reg[0];

//counter logic for baud count
logic [12:0] baud_cnt;
always_ff @(posedge clk) begin
    if (load | shift)
        baud_cnt <= 13'b0;
    else if (transmitting)
        baud_cnt <= baud_cnt + 1;
end

assign shift = (baud_cnt == 13'd5208) ? 1'b1 : 1'b0; //5208 for 9600 baud with 50MHz clock


//counter logic for bit count
logic [3:0] bit_cnt;
always_ff @(posedge clk) begin
    if (load)
        bit_cnt <= 4'b0;
    else if (shift)
        bit_cnt <= bit_cnt + 1;
end


//flip flop for state transition
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) 
        cur_state <= IDLE;
    else
        cur_state <= nxt_state;
end

//S-R flops for tx_done output

logic set_sr;
logic rst_sr;
//combinational logic for state output
always_comb begin

    transmitting = 1'b0;
    nxt_state = cur_state;
    load = 1'b0;
    rst_sr = 1'b0;
    set_sr = 1'b0;

    case (cur_state)
        IDLE: begin
            if (trmt) begin
                //transition to transmitting state
                nxt_state = TRANSMITTING;
                transmitting = 1'b1;
                load = 1'b1;
                rst_sr = 1'b1;
            end
        end
        TRANSMITTING: begin
            transmitting = 1'b1;
            if (bit_cnt == 4'd10) begin
                nxt_state = IDLE;
                set_sr = 1'b1;
            end
        end
    endcase
end 



always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        tx_done <= 1'b0;
    else if (set_sr)
        tx_done <= 1'b1;
    else if (rst_sr)
        tx_done <= 1'b0;

endmodule
