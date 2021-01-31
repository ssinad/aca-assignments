module tb;
	parameter n = 32;
	parameter no_of_tests = 10000;
	
	reg clk = 1, start = 0, is_signed;
	reg [n - 1:0] a, b, m1, m2;
	integer cnt, err = 0;
	wire [2 * n - 1:0] s;
	
	multiplier mu(
        clk,            // module clock, everything should be done in positive edge of it
        start,          // indicates all inputs are valid and multiplication should be started
        is_signed,      // when 1, signed multiplication is intended, otherwise, it's unsigned
        a,   // first operand,
        b,   // second operand
        s   // output result
    );
	
	initial
		forever
			#1 clk = !clk;
	
	initial
	begin
		
		give_and_check(-1, -1, 1);
		give_and_check(6, -1, 1);
		give_and_check((1 << n - 1), -1, 1);
		give_and_check(-1, (1 << n - 1), 1);
		$stop;
		give_and_check(-1, 6, 1);
		give_and_check(3, 3, 1);
		
		give_and_check(-1, -1, 0);
		give_and_check(6, -1, 0);
		give_and_check(-1, 6, 0);
		give_and_check((1 << n - 1), -1, 0);
		give_and_check(-1, (1 << n - 1), 0);
		
		give_and_check (1 << (n - 1), 1 << (n - 1), 0);
		give_and_check (1 << (n - 1), 1 << (n - 1), 1);
		give_and_check(3, 3, 0);
		
		for(cnt = 0; cnt < no_of_tests; cnt = cnt + 1) begin

            m1 = $random();    // support of ni up to 128
            m2 = $random();
			give_and_check(m1, m2, 0);
			give_and_check(m1, m2, 1);
		end
		if (!err)
			$display("Hooray! No Errors!");
		else
			$display("%d errors were found!", err);
		$stop;
	end
	
	task give_and_check;
	input [n - 1:0] n1, n2;
	input sign;
	reg signed [2 * n - 1:0] s1;
	reg [2 * n - 1:0] s2;
	begin
		@(posedge clk);
		a = n1;
		b = n2;
		is_signed = sign;
		start = 1;
		s1 = $signed(n1) * $signed(n2);
		s2 = $unsigned(n1) * $unsigned(n2);
		@(posedge clk);
		start = 0;
		a = 0;
		b = 0;
		#40;
		
		
		if ((is_signed && s1 == s) || (!is_signed && s2 == s))
		begin
			if (!is_signed)
			begin
				$display("Unsigned Multiplication!");
				$display("%d * %d = %d! OK", $unsigned(n1), $unsigned(n2), $unsigned(s));
			end
			else
			begin
				$display("Signed Multiplication!");
				$display("%d * %d = %d! OK", $signed(n1), $signed(n2), $signed(s));
			end
		end
		else
		begin
			$display("Error");
			err = err + 1;
			if (!is_signed)
			begin
				$display("Unsigned Multiplication!");
				$display("%d * %d: Expected %d but got %d", $unsigned(n1), $unsigned(n2), s2, $unsigned(s));
				$display("%b", s2 ^ s);
			end
			else
			begin
				$display("Signed Multiplication!");
				$display("%d * %d: Expected %d but got %d", $signed(n1), $signed(n2), s1, $signed(s));
				$display("%b", s1 ^ s);
			end
			$stop;
		end
		
	end
	endtask
endmodule