
`timescale 1ns/10ps

module some_tbs;
	single_cycle_mips__tb #("isort32.hex", 1'b1) is32();
	//single_cycle_mips__tb #("isort32m.hex", 1'b0) is32m();
	//single_cycle_mips__tb #("my_code.hex", 1'b0) smjst();
	//single_cycle_mips__tb #("tstm_93202112.hex", 1'b0) mk();
endmodule

module single_cycle_mips__tb;
parameter hex_file = "isort32.hex", sort = 1'b1;

	reg clk = 1;
	always @(clk)
		clk <= #10 ~clk;

	reg reset;
	initial begin
		reset = 1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		#1;
		reset = 0;
	end
	integer i;
	initial
	begin
		$readmemh(hex_file, uut.inst_mem.mem_data);
		$readmemh(hex_file, uut.data_mem.mem_data);
		#1000000 ;
		for(i=0; i<96; i=i+1) begin
				$write("%x ", uut.data_mem.mem_data[32+i]);
				if(((i+1) % 16) == 0)
					$write("\n");
			end
			$stop;
	end

	parameter end_pc = (hex_file == "isort32.hex")?32'h78:32'h84;

	
	always @(uut.pc)
		if(uut.pc == end_pc && sort) begin
			for(i=0; i<96; i=i+1) begin
				//$write("%x ", uut.data_mem.mem_data[32+i]);
				if(((i+1) % 16) == 0);
					//$write("\n");
			end
			//$stop;
		end
	
	single_cycle_mips uut(
		.clk(clk),
		.reset(reset)
	);


endmodule
