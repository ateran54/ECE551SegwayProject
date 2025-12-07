module Auth_blk(
    input  logic       clk,         // 50MHz system clock
    input  logic       rst_n,       // active low reset
    input  logic       RX,          // UART receive line from BLE module
    input  logic       rider_off,   // signal indicating rider weight < MIN_RIDER_WEIGHT
    output logic       pwr_up       // power up signal to balance_cntrl
);

    // UART receiver interface signals
    logic       rx_rdy;
    logic [7:0] rx_data;
    logic       clr_rx_rdy;

    // Authorization codes
    localparam logic [7:0] AUTH_CODE_GO   = 8'h47; // 'G' - power up
    localparam logic [7:0] AUTH_CODE_STOP = 8'h53; // 'S' - power down request

    // State machine definition
    typedef enum logic [1:0] {
        POWERED_DOWN = 2'b00,   
        POWERED_UP   = 2'b01,   
        STOP_PENDING = 2'b10    // Stop received, waiting for rider to get off
    } auth_state_t;

    auth_state_t current_state, next_state;

    // Instantiate UART receiver
    // changed baud rate to parameter
    UART_rx uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .clr_rdy(clr_rx_rdy),
        .rdy(rx_rdy),
        .rx_data(rx_data)
    );

    // State machine sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= POWERED_DOWN;
        end else begin
            current_state <= next_state;
        end
    end

    // State machine combinational logic
    always_comb begin
        next_state = current_state;
        clr_rx_rdy = 1'b0;
        pwr_up = 1'b0;
        
        case (current_state)
            POWERED_DOWN: begin
                if (rx_rdy) begin
                    clr_rx_rdy = 1'b1;  // Clear the ready flag
                    if (rx_data == AUTH_CODE_GO) begin
                        next_state = POWERED_UP;
                    end
                end
            end

            POWERED_UP: begin
                pwr_up = 1'b1;
                if (rx_rdy) begin
                    clr_rx_rdy = 1'b1;  // Clear the ready flag
                    if (rx_data == AUTH_CODE_STOP) begin
                        if (rider_off) begin
                            next_state = POWERED_DOWN;
                        end else begin
                            next_state = STOP_PENDING;
                        end
                    end else if (rx_data == AUTH_CODE_GO) begin
                        next_state = POWERED_UP;
                    end
                end
            end

            STOP_PENDING: begin
                pwr_up = 1'b1;
                if (rx_rdy) begin
                    clr_rx_rdy = 1'b1;  // Clear the ready flag
                    if (rx_data == AUTH_CODE_GO) begin
                        next_state = POWERED_UP;
                    end else if (rx_data == AUTH_CODE_STOP) begin
                        if (rider_off) begin
                            next_state = POWERED_DOWN;
                        end
                    end
                end else begin
                    if (rider_off) begin
                        next_state = POWERED_DOWN;
                    end
                end
            end

            default: begin
                next_state = POWERED_DOWN;
            end
        endcase
    end


endmodule