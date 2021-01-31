
`timescale 1ns/1ns

module frac_divider__tb();

	parameter ni = 32;
	parameter no = 40;
    parameter no_of_tests = 10000;

    reg clk = 1'b1;
    always @(clk)
        clk <= #5 ~clk;

    integer i, j, err = 0;
    reg [-1:-ni] a, b;
    reg [0:-no] q;
    reg start;

    initial begin
        start = 0;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;

        for(i=0; i<no_of_tests; i=i+1) begin

            a = {$random(), $random(), $random(), $random()};    // support of ni up to 128
            b = {$random(), $random(), $random(), $random()};

			a[-1] = 1'b1;		// make sure a and b are normalized
			b[-1] = 1'b1;

			q = {a, {no{1'b0}}}/b;

            start = 1;
            @(posedge clk);
            #1;
            start = 0;

            for(j=-1; j<=no; j=j+1)
                @(posedge clk);

			$write("0.%x (%0f) / 0.%x (%0f) = %b.%x (%0f)", a, a/(2.0**ni), b, b/(2.0**ni), uut.q[0], uut.q[-1:-no], uut.q/(2.00**no),);

			if( q === uut.q )
                $display("OK");
            else begin
                err = err + 1;
                $display("ERROR: expected %x, got %x", q, uut.q);
				$stop;
            end



        end

        if(err)
            $display("\n\tOops, %0d (%%%0d) errors are found.\n", err, (err*100+no_of_tests/2)/no_of_tests);
        else
            $display("\n\tGREAT, no errors found.\n");

        $stop;
    end


    frac_divider #(.ni(ni), .no(no)) uut (
        .clk(clk),
        .start(start),
        .a(start ? a : {ni{1'bx}}),
        .b(start ? b : {ni{1'bx}}),
        .q()
    );




endmodule

