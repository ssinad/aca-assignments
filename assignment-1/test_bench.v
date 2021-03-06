
`timescale 1ns/1ns

module test_bench();


    parameter no_of_tests = 10000;

    reg clk = 1'b1;
    always @(clk)
        clk <= #5 ~clk;

    integer i, j, err = 0;
    reg [31:0] a, b;
    reg [63:0] s;
    reg start;

    initial begin
        start = 0;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;

        for(i=0; i<no_of_tests; i=i+1) begin

            a = $random();    // support of ni up to 128
            b = $random();

     //a[0] = 1'b0;		// make sure a and b are normalized
      //b[0] = 1'b0;

      s = a* b;

            start = 1;
            @(posedge clk);
            #1;
            start = 0;

            for(j=0; j<=17; j=j+1)
                @(posedge clk);

      $write("%d * %d = %d   %d", a, b, s, uut.s);

      if( s === uut.s )
                $display("OK");
            else begin
                err = err + 1;
                $display("ERROR: expected %x, got %x", s, uut.s);
            end



        end
        $stop;
        end

      //  if(err)
     //  ; //$display("\n\tOops, %0d (%%%0d) errors are found.\n", err, (err*100+no_of_tests/2)/no_of_tests);
      //  else
          //  $display("\n\tGREAT, no errors found.\n");
       // $stop;
   // end


    multiplier  uut (
    .clk(clk),
        .start(start),
        .a(start ? a : {32{1'bx}}),
        .b(start ? b : {32{1'bx}}),
        .s(),
        .is_signed(1'b0)
    );

endmodule

