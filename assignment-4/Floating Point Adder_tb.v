

`timescale 1ns/1ns

module fp_add__tb();

   integer i, j, result_err, bit_err;

   reg [31:0] a, b, c, d, data[0:40000];

   initial begin

      bit_err = 0;
      result_err = 0;

      $readmemh("fp.hex", data);	// copy the file in simulation directory
//    $readmemh("D:\work\ACA93\fp.hex", data);	// or just use it's complete address 

      if(data[0] === 32'bx) begin
         $display("\n\tInput file is not read properly,\n\tmake sure it is located in ModelSim home directory,\n\tor use absolute folder address in $readmemh");
         $display("\n\tNo test-vector is applied, fix the problem and re-run the test-bench\n\n");
         $stop;
      end

      for(i=0; i<10000; i=i+1) begin

         a = data[i*4+0];
         b = data[i*4+1];
         c = data[i*4+2];
         d = data[i*4+3];
         #10;

         if(uut.s !== c) begin
            result_err = result_err + 1;
            $write("\tError: %8x + %8x, expected: %8x, but got: %8x\n", a, b, c, uut.s);
            if (uut.s[31] !== c[31])
              $write("\t\t Sign Error in Addition *******************\n");
         end

         if(uus.s !== d) begin
            result_err = result_err + 1;
            $write("\tError: %8x - %8x, expected: %8x, but got: %8x\n", a, b, d, uus.s);
            if (uus.s[31] !== d[31])
              $write("\t\t Sign Error in Subtraction ****************\n");
         end

         for(j=0; j<32; j=j+1)
            if(c[j] !== uut.s[j])
               bit_err = bit_err + 1;

         for(j=0; j<32; j=j+1)
            if(d[j] !== uus.s[j])
               bit_err = bit_err + 1;

      end

      if(result_err) begin
         $write("\n\n\tTotal Errors in the Results: %4d\n", result_err);
         $write("\tTotal Bit Mismatches in the Results: %d\n", bit_err);
      end
      else
         $write("\n\n\tWow!! NO ERROR Found. Great Job.\n\n");

   end

   fp_adder uut( .a(a), .b(b), .s());              // a + b
   fp_adder uus( .a(a), .b(b ^ 32'h80000000), .s());  // a - b

endmodule
