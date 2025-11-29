module balance_cntrl_chk_tb();
    logic [48:0] mem_stim[1499:0];
    logic [24:0] mem_resp[1499:0];

    logic [48:0] cur_stim;
    logic [24:0] cur_resp;

    // store file paths in variables
    string stim_file  = "Testing/ModuleSpecific/BalanceCntrl/balance_cntrl_stim.hex";
    string resp_file  = "Testing/ModuleSpecific/BalanceCntrl/balance_cntrl_resp.hex";
    int    fd;

    //signals
    logic clk;
    logic rst_n;
    logic vld;
    logic [15:0] ptch;
    logic [15:0] ptch_rt;
    logic pwr_up;
    logic rider_off;
    logic [11:0] steer_pot;
    logic en_steer;
    
    //outputs
    logic [11:0] lft_spd;
    logic [11:0] rght_spd;
    logic too_fast;

    balance_cntrl idut(
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    //load in memory
    initial begin
        // check stimulus file exists
        fd = $fopen(stim_file, "r");
        if (fd == 0) begin
            $display("ERROR: Stimulus file not found: %s", stim_file);
            $stop;
        end
        $fclose(fd);

        // check response file exists
        fd = $fopen(resp_file, "r");
        if (fd == 0) begin
            $display("ERROR: Response file not found: %s", resp_file);
            $stop;
        end
        $fclose(fd);

        // load memories using the variables
        $readmemh(stim_file, mem_stim);
        $readmemh(resp_file, mem_resp);

        force idut.ss_tmr = 8'hFF;
        clk = 0;

        //initialize default inputs
        cur_stim = 49'h0;
        cur_resp = 25'h0;
        rst_n = 0;
        vld = 0;
        ptch = 0;
        ptch_rt = 0;
        pwr_up = 0;
        rider_off = 0;
        steer_pot = 0;
        en_steer = 0;
        lft_spd = 0;
        rght_spd = 0;
        too_fast = 0;   
        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);
        //apply stim and check responses
                
        for (int i = 0; i < 1500; i=i+1) begin
            cur_stim = mem_stim[i];
            cur_resp = mem_resp[i];
            //set stim variables
            rst_n = cur_stim[48];
            vld = cur_stim[47];
            ptch = cur_stim[46:31];
            ptch_rt = cur_stim[30:15];
            pwr_up = cur_stim[14];
            rider_off = cur_stim[13];
            steer_pot = cur_stim[12:1];
            en_steer = cur_stim[0];
            //wait one clk cycle
            @(posedge clk);
            #1;
            //check our output against output stim
            if ((lft_spd === cur_resp[24:13]) && (rght_spd === cur_resp[12:1]) && (too_fast === cur_resp[0])) begin 
                $display("Stim %d Passed! Expected: lft_spd = %h, rght_spd = %h, resp = %h. Actual: lft_spd = %h, rght_spd = %h, resp = %h", 
                    i, cur_resp[24:13], cur_resp[12:1], cur_resp[0], lft_spd, rght_spd, too_fast);
            end else begin
                $display("Stim %d Failed! Expected: lft_spd = %h, rght_spd = %h, resp = %h. Actual: lft_spd = %h, rght_spd = %h, resp = %h", 
                    i, cur_resp[24:13], cur_resp[12:1], cur_resp[0], lft_spd, rght_spd, too_fast);
                $stop;
            end
        end
        $display("YAHOO!!! All Tests passed!");
        $stop;
    end 





always #5 clk = ~clk; // Clock generator
endmodule
