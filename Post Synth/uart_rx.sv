module UART_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        RX,
    input  logic        clr_rdy,
    output logic [7:0]  rx_data,
    output logic        rdy
);

//State logic
typedef enum {IDLE, RECEIVING} state_t;
state_t cur_state, nxt_state;     

//internal signals
logic start;
logic shift;
logic receiving;
logic set_rdy;
logic [12:0] baud_cnt;
logic [3:0] bit_cnt;


//counter logic for baud count
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 13'd0;
    else if (start)
        baud_cnt <= 13'd2604; //2604 for half bit delay at start, else 0
    else if (shift)
        baud_cnt <= 13'd5208; //5208 for 9600 baud with 50MHz clock
    else if (receiving)
        baud_cnt <= baud_cnt - 1;
end
assign shift = (baud_cnt == 13'd0) ? 1'b1 : 1'b0; //5208 for 9600 baud with 50MHz clock

//flip flop for state transition
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) 
        cur_state <= IDLE;
    else
        cur_state <= nxt_state;
end

//counter logic for bit count
always_ff @(posedge clk, negedge rst_n) begin  
    if(!rst_n)
        bit_cnt <= 13'd0;
    else if (start)
        bit_cnt <= 4'b0;
    else if (shift)
        bit_cnt <= bit_cnt + 1;
end
assign set_rdy = (bit_cnt == 4'd10) ? 1'b1: 1'b0;

//double flop RX
logic rx_dbl_ff_1;
logic rx_dbl_ff_2;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) 
        rx_dbl_ff_1 <= 1'b1;
    else
        rx_dbl_ff_1 <= RX;
end

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        rx_dbl_ff_2 <= 1'b1;
    else
        rx_dbl_ff_2 <= rx_dbl_ff_1;
end




logic set_sr;
logic rst_sr;



//state machine
always_comb begin
    nxt_state = cur_state;
    start = 1'b0;
    receiving = 1'b0;
    set_sr = 1'b0;
    rst_sr = 1'b0;

    case (cur_state)
        IDLE: begin
            if (rx_dbl_ff_2 == 1'b0) begin
                start = 1'b1;
                receiving = 1'b1;
                nxt_state = RECEIVING;
                rst_sr = 1'b1;
            end
            else if (clr_rdy)
                rst_sr = 1'b1;
        end
        RECEIVING: begin
            receiving = 1'b1;
            if (set_rdy) begin // All bits received (1 start, 8 data, 1 stop)
                nxt_state = IDLE;
                set_sr = 1'b1;
            end
        end
    endcase
end

    
//shift register logic
logic [8:0] rx_shft_reg;
always_ff @(posedge clk) begin
    if (start)
        rx_shft_reg <= 8'b0;
    else if (shift)
        rx_shft_reg <= {rx_dbl_ff_2, rx_shft_reg[8:1]};
end

assign rx_data = rx_shft_reg[7:0];

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        rdy <= 1'b0;
    else if (set_sr)
        rdy <= 1'b1;
    else if (rst_sr)
        rdy <= 1'b0;

endmodule