`timescale 1ns/ 1ns

module test_bench;
  
  
  reg clk, start, iss;
  reg [31:0] a, b;
  wire [63:0] sum;
  
  multiplier mul( .clk(clk), .a(a), .b(b), .start(start), .is_signed(iss), .s(sum) );
  
  initial
    clk= 0;
  
  always
    begin
      #10 clk= 0;
      #10 clk= 1;
      $monitor("Clock is = %b,s is = %d,a is = %d", clk, sum, a);
    end
    
  initial
    begin
      start= 0;
      a= 0;
      b= 0;
      iss= 0;
      #20 start= 1;
      a=3000000000;
      b=3000000000;
      #30 start= 0;
      a=0;
      b=0;   
      #600 start= 1;
      iss= 0;
      a=2999092324;
      b=2302104082;
      #610 start= 0;
      #620 start= 1;
      iss= 0;
      a=303379748;
      b=3230228096; 
      #630 start= 0;
      //#10000 $stop;
    end
    
    
    
endmodule