module frac_divider
    #(
        parameter ni = 32,          // number of inputs fractional bits
        parameter no = 40           // number of output fractional bits after point
    )
    (
        input clk,                  // module clock, everything should be done in positive edges
        input start,                // indicates all inputs are valid and divide should be initiated
        input [-1 : -ni] a,         // dividend, in fractional format: 0.a[-1] ... a[-ni]
        input [-1 : -ni] b,         // divisor, in fractional format:  0.b[-1] ... b[-ni]
        output [0 : -no] q          // quotient: q[0].q[-1] ... q[-no] = a / b
    );
	localparam nb = $clog2(no + 2);
	
	reg [ni:0] R;
	reg [ni - 1:0] B;
	reg [nb - 1:0] cnt;
	reg [no:0] Q;
	
	wire init, ldR, cnt_finished;
	
	wire [ni - 1:0] Diff, new_R;
	wire borrow ,cout;
	
	assign {cout, Diff} = (R - B);
	assign borrow = (R < B);//!cout
	assign new_R = (borrow)? R : Diff;
	
	always @(posedge clk)
	begin
		if (init)
			B <= b;
	end
	
	always @(posedge clk)
	begin
		if (init)
			R <= a;
		else if (ldR)
			R <= {new_R, 1'b0};
	end
	
	always @(posedge clk)
	begin
		if (init)
			Q <= 0;
		else if (ldR)
			Q <= {Q[no - 1:0], !borrow};
	end
	
	always @(posedge clk)
	begin
		if (init)
			cnt <= 0;
		else if (ldR)
			cnt <= cnt + 1'b1;
	end
	
	assign cnt_finished = (cnt == no);
	
	ctrl cu(clk, start, cnt_finished, init, ldR);
	
	assign q = Q;
	
endmodule

module ctrl(
	clk,
	start,
	cnt_finished,
	init,
	ldR
);
	localparam ready = 1'b0, counting = 1'b1, stable = 2'd2;
	input clk, start, cnt_finished;
	output reg init, ldR;
	reg [2:0] current_state = ready, next_state;
	
	always @(posedge clk)
		current_state <= next_state;
		
	always @(*)
	begin
		next_state = ready;
		case (current_state)
		ready:
			if (start)
				next_state = counting;
			else
				next_state = ready;
		counting:
			if (cnt_finished)
				next_state = ready;
			else
				next_state = counting;

		endcase
	end
	
	always @(*)
	begin
		init = 1'b0;
		ldR = 1'b0;
		case (current_state)
			ready:
				if (start)
					init = 1'b1;
			counting:
				ldR = 1'b1;
		endcase
	end
endmodule