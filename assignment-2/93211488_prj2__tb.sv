module tb;
	reg [7:0] a, b;
	wire [15:0] p;
	reg[15:0] expected_p;
	
	integer cnt, no_tests = 10000;
	
	wallace_tree_multiplier wtm_uut(a, b, p);
	
	initial
	begin
		for (cnt = 0; cnt < no_tests; cnt = cnt + 1)
		begin
			a = $random();
			b = $random();
			#1;
			expected_p = a * b;
			if (expected_p != p)
			begin
				$display("Error\n%d * %d expected %d but got %d", a, b, expected_p, p);
				$stop;
			end
		end
		$stop;
	end
endmodule
