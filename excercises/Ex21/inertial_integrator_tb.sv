//team Turtle
`timescale 1ns/1ps
module intertial_integrator_tb();

	// Testbench signals
	logic clk;
	logic rst_n;
	logic vld;
	logic signed [15:0] ptch_rt;
	logic signed [15:0] AZ;
	logic signed [15:0] ptch;
    int cycles;

	// Constants matching DUT localparams
	localparam logic signed [15:0] PTCH_RT_OFFSET = 16'sh0050;

	// Instantiate DUT (note module name has the intentional spelling 'intertial')
	intertial_integrator dut (
		.clk(clk),
		.rst_n(rst_n),
		.vld(vld),
		.ptch_rt(ptch_rt),
		.AZ(AZ),
		.ptch(ptch)
	);

	// Clock generation: 10ns period
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	// Helper: wait N positive edges
	task automatic wait_cycles(input int n);
		int i;
		for (i = 0; i < n; i = i + 1) @(posedge clk);
	endtask

	// Main stimulus sequence
	initial begin
		// Initialize
		rst_n = 0;
		vld   = 0;
		ptch_rt = 16'sd0;
		AZ = 16'sd0;

		// Hold reset for a few cycles
		repeat (5) @(posedge clk);
		#1; // small delta
		rst_n = 1;
		vld = 1; // ensure vld is held high during stimuli as requested

		// 1) After reset: apply ptch_rt = 16'h1000 + PTCH_RT_OFFSET, AZ = 0, vld=1 for 500 clocks
		ptch_rt = $signed(16'h1000) + PTCH_RT_OFFSET;
		AZ = 16'sd0;
		wait_cycles(500);

		// 2) Zero out pitch rate: apply PTCH_RT_OFFSET for 1000 clocks
		ptch_rt = PTCH_RT_OFFSET;
		wait_cycles(1000);

		// 3) Apply PTCH_RT_OFFSET - 16'h1000 for 500 clocks (opposite sign)
		ptch_rt = PTCH_RT_OFFSET - $signed(16'h1000);
		wait_cycles(500);

		// 4) Zero out again for 1000 clocks
		ptch_rt = PTCH_RT_OFFSET;
		wait_cycles(1000);

		// 5) Set AZ to 16'h0800 and wait until ptch approaches ~100 (or timeout)
		AZ = 16'h0800;
		cycles = 0;
		// wait until ptch in [90,110] or timeout after 5000 cycles
		while (!((ptch >= 90) && (ptch <= 110)) && (cycles < 5000)) begin
			wait_cycles(1);
			cycles = cycles + 1;
		end

        #100;
		$stop;
	end

	// Periodic status print every 1000ns for coarse tracking
	always @(posedge clk) begin
		if ($time % 1000 == 0) begin
			$display("%0t ns: ptch_rt=0x%h AZ=0x%h ptch=%0d", $time, ptch_rt, AZ, ptch);
		end
	end

endmodule