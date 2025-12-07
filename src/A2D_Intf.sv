module A2D_intf (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        nxt,
    output logic [11:0] lft_ld,
    output logic [11:0] rght_ld,
    output logic [11:0] steer_pot,
    output logic [11:0] batt,
    output logic        SS_n,
    output logic        SCLK,
    output logic        MOSI,
    input  logic        MISO
);

    localparam logic [2:0] CHANNEL0 = 4'b000;
    localparam logic [2:0] CHANNEL4 = 4'b100;
    localparam logic [2:0] CHANNEL5 = 4'b101;
    localparam logic [2:0] CHANNEL6 = 4'b110;

    typedef enum logic [1:0] {IDLE, T1, DEAD, T2} state_t;

    state_t currState, nextState;
    logic [1:0] robin_cnt;
    logic [15:0] wt_data, rd_data;
    logic wrt, done, count_en;

    logic [11:0] nextLeftLoadLevel;
    logic [11:0] nextRightLoadLevel;
    logic [11:0] nextSteeringPotentiometer;
    logic [11:0] nextBatteryVoltage;

    SPI_mnrch u_spi_mnrch (
        .clk      (clk),
        .rst_n    (rst_n),
        .SS_n     (SS_n),
        .SCLK     (SCLK),
        .MOSI     (MOSI),
        .MISO     (MISO),
        .wrt_data  (wt_data),
        .wrt      (wrt),
        .done     (done),
        .rd_data  (rd_data)
    );

    always_comb begin
        wrt       = 1'b0;
        count_en  = 1'b0;
        nextState = currState;
        nextLeftLoadLevel = lft_ld;
        nextRightLoadLevel = rght_ld;
        nextSteeringPotentiometer = steer_pot;
        nextBatteryVoltage = batt;

        case (robin_cnt)
            2'b00: wt_data = {2'b00, CHANNEL0, 11'b0};
            2'b01: wt_data = {2'b00, CHANNEL4, 11'b0};
            2'b10: wt_data = {2'b00, CHANNEL5, 11'b0};
            2'b11: wt_data = {2'b00, CHANNEL6, 11'b0};
            default: wt_data = 16'd0;
        endcase



        case (currState)
            IDLE: begin
                if (nxt) begin
                    wrt       = 1'b1;
                    nextState = T1;
                end
            end

            T1: begin
                if (done)
                    nextState = DEAD;
            end

            DEAD: begin
                wt_data = 16'd1;
                wrt = 1;
                nextState = T2;
            end
            // todo chnage the RD FOR enables.
            T2: begin
                if (done) begin // chnacge for a decoder this is stupid.
                    count_en = 1'b1;
                    case (robin_cnt)
                        2'b00: nextLeftLoadLevel         = rd_data[11:0];
                        2'b01: nextRightLoadLevel        = rd_data[11:0];
                        2'b10: nextSteeringPotentiometer = rd_data[11:0];
                        2'b11: nextBatteryVoltage        = rd_data[11:0];
                    endcase
                    nextState = IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            robin_cnt <= 2'd0;
        else if (count_en) begin
                robin_cnt <= robin_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            currState <= IDLE;
        else
            currState <= nextState;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lft_ld     <= 12'd0;
            rght_ld    <= 12'd0;
            steer_pot  <= 12'd0;
            batt       <= 12'd0;
        end else if (count_en) begin
            lft_ld     <= nextLeftLoadLevel;
            rght_ld    <= nextRightLoadLevel;
            steer_pot  <= nextSteeringPotentiometer;
            batt       <= nextBatteryVoltage;
        end
    end

endmodule
