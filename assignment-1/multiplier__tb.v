
`timescale 1ns/1ns

module multiplier__tb();

    parameter nb   = 32;
    parameter no_of_tests = 10000;

    reg clk = 1'b1;
    always @(clk)
        clk <= #5 ~clk;

    reg start;
    integer i, j, err = 0;
    reg [  nb-1:0] a, b;
    reg [2*nb-1:0] p;
    
    reg signed [  nb-1:0] c, d;
    reg signed [2*nb-1:0] q;


    initial begin
        start = 0;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;

        for(i=0; i<no_of_tests; i=i+1) begin

            a = {$random(), $random(), $random(), $random()};    // support of nb up to 128
            b = {$random(), $random(), $random(), $random()};

            c = a;
            d = b;

            p = a * b;
            q = c * d;

            start = 1;
            @(posedge clk);
            #1;
            a = 'bx;
            b = 'bx;
            start = 0;

//          for(j=0; j<=nb; j=j+1)        // Non-Booth
            for(j=0; j<=(nb/2); j=j+1)    // Booth
                @(posedge clk);
            @(posedge clk);

            // unsigned input and output
            if (p === uut.s)
;//                $display("OK");
            else begin
                err = err + 1;
                if(err < 20) begin
                  $write("%x (%0d) * %x (%0d) = %x (%0d) ", {c}, {c}, {d}, {d}, uut.s, uut.s);
                   $display("ERROR: expected %x, got %x", p, uut.s);
               end
            end

            // signed input and output
            if (q === sut.s)
;//                $display("OK");
            else begin
                err = err + 1;
                if(err < 20) begin
                  $write("%x (%0d) * %x (%0d) = %x (%0d) ", c, c, d, d, sut.s, sut.s);
                   $display("ERROR: expected %x, got %x", q, sut.s);
               end
            end

        end

        if(err)
            $display("\n\tOops, %0d (%%%0d) errors are found.\n", err, (err*100+no_of_tests)/(2*no_of_tests));
        else
            $display("\n\tGREAT, no errors found.\n");

        $stop;
    end


    multiplier #(.n(nb)) uut (        // unsigned unit
        .clk(clk),
        .start(start),
        .is_signed(start ? 1'b0 : 1'bx),
        .a(a),
        .b(b),
        .s()
    );

    multiplier #(.n(nb)) sut (        // signed unit
        .clk(clk),
        .start(start),
        .is_signed(start ? 1'b1 : 1'bx),
        .a(a),
        .b(b),
        .s()
    );

endmodule
