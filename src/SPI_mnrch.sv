module SPI_mnrch (
    input logic clk,        // 50MHz system clock
    input logic rst_n,      // Reset (active low)
    input logic MISO,      // Master In Slave Out
    input logic wrt,        // Write signal to initiate SPI transaction
    input logic [15:0] wrt_data,  // Data (command) to send to inertial sensor
    output logic done,      // Asserted when SPI transaction is complete
    output logic [15:0] rd_data, // Data read from SPI slave
    output logic SS_n,       // SPI Slave Select (active low)
    output logic SCLK,       // SPI Clock
    output logic MOSI       // Master Out Slave In
);
    //Logic signals from FSM
    logic ld_SCLK;
    logic init;
    logic shft;
    //Logic signals to FSM
    logic done15;
    logic shft_imm;
    //other datapath signals
    logic smpl;

    //clock division and decode logic
    logic [3:0] SCLK_div;
    always_ff @(posedge clk) begin
        if (!ld_SCLK) begin
            SCLK_div <= SCLK_div + 1;
        end else begin
            SCLK_div <= 4'b1011;
        end
    end
    assign SCLK = SCLK_div[3];

    assign smpl = (SCLK_div == 4'b0111);
    assign shft_imm = (SCLK_div == 4'b1111);

    //bit_cnt logic
    logic [3:0] bit_cntr;
    always_ff @(posedge clk) begin  
        if (init) begin
            bit_cntr <= 4'b0000;
        end else if (shft) begin
            bit_cntr <= bit_cntr + 1;
        end 
    end
    assign done15 = &bit_cntr;

    //MISO and MOSI data
    logic MISO_SMPL;
    always_ff @(posedge clk) begin 
        if (smpl)
            MISO_SMPL <= MISO;
    end


    logic [15:0] shft_reg;
    always_ff @(posedge clk) begin  
        if (init) begin
            shft_reg <= wrt_data;
        end
        else if (shft) begin
            shft_reg <= {shft_reg[14:0], MISO_SMPL};
        end 
    end

    assign MOSI = shft_reg[15];
    assign rd_data = shft_reg;
    //logic to set signals for flops
    logic set_done;

    //State Machine
    typedef enum {IDLE, FRONT, WORK, BACK} state_t;
    state_t cur_state, nxt_state;

    always_comb begin
        nxt_state = cur_state;
        ld_SCLK = 0;
        init = 0;
        shft = 0;
        set_done = 0;

        case (cur_state)
            IDLE: begin
                if (wrt) begin
                    nxt_state = FRONT;
                    init = 1;
                end
                else begin
                    ld_SCLK = 1;
                end
            end
            FRONT: begin
                if (shft_imm) begin
                    nxt_state = WORK;
                end
            end
            WORK: begin
                if (shft_imm) begin
                    shft = 1;
                end                
                if (done15) begin
                    nxt_state = BACK;
                end
            end
            BACK: begin
                if (shft_imm) begin
                    shft = 1;
                    ld_SCLK = 1;
                    set_done = 1;
                    nxt_state = IDLE;
                end
            end
        endcase
    end

    //flip flop for state transition
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            cur_state <= IDLE;
        else
            cur_state <= nxt_state;
    end

    //S-R flops for done and SS_n
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            done <= 1'b0;
        else if (set_done)
            done <= 1'b1;
        else if (init)
            done <= 1'b0;
    
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            SS_n <= 1'b1;
        else if (set_done)
            SS_n <= 1'b1;
        else if (init)
            SS_n <= 1'b0;

endmodule
