
`timescale 1ns/1ns

module multi_cycle_mips__tb;

	reg clk = 1;
	always @(clk)
		clk <= #5 ~clk;

	reg reset;
	initial begin
		reset = 1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		#1;
		reset = 0;
	end

	initial
		$readmemh("isort32.hex", uut.mem.mem_data);

	parameter end_pc = 32'h7C;

	integer i;
	always @(uut.pc)
		if(uut.pc == end_pc) begin
			for(i=0; i<96; i=i+1) begin
				$write("%x ", uut.mem.mem_data[32+i]);
				if(((i+1) % 16) == 0)
					$write("\n");
			end
			$stop;
		end

	multi_cycle_mips uut(
		.clk(clk),
		.reset(reset)
	);


endmodule
