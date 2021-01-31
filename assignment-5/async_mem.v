
`timescale 1ns/1ns

module async_mem(
   input clk,
   input write,
   input [31:0] address,
   input [31:0] write_data,
   output [31:0] read_data
);


   reg [31:0] mem_data [0:1023];

   assign #7 read_data = mem_data[ address[31:2] ];

   always @(posedge clk)
      if(write)
         mem_data[ address[31:2] ] <= #2 write_data;

endmodule	