
`timescale 1ns/10ps

module multi_cycle_mips__tb;

   reg clk = 1;
   always @(clk)
      clk <= #1.25 ~clk;

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
      $readmemh("isort32m.hex", uut.mem.mem_data);

   parameter end_pc = 32'h7C;
// parameter end_pc = 32'h30;

   integer i;
   always @(uut.pc)
      if(uut.pc == end_pc) begin
         for(i=0; i<96; i=i+1) begin
            $write("%x ", uut.mem.mem_data[12+i]); // 32+ for iosort32
            if(((i+1) % 16) == 0)
               $write("\n");
         end
		 for(i=0; i<96 - 1; i=i+1) begin
            if (uut.mem.mem_data[12+i] < uut.mem.mem_data[12+i + 1])
				$display("wrong sort");// 32+ for iosort32
           
         end
         $stop;
      end

   multi_cycle_mips uut(
      .clk(clk),
      .reset(reset)
   );


endmodule
