
`timescale 1ns/100ps

//`define DEBUG   // comment this line to disable register content writing below

module reg_file(
   input clk,
   input write,
   input [4:0] WR,
   input [31:0] WD,
   input [4:0] RR1,
   input [4:0] RR2,
   output [31:0] RD1,
   output [31:0] RD2
);

   reg [31:0] rf_data [0:31];

   assign #2 RD1 = rf_data[ RR1 ];

   assign #2 RD2 = rf_data[ RR2 ];

   always @(posedge clk) begin
      if(write) begin
         rf_data[ WR ] <= #0.1 WD;

         `ifdef DEBUG
         if(WR)
            $display("$%0d = %x", WR, WD);
         `endif

      end
      rf_data[0] <= #0.1 32'h00000000;
   end

endmodule	