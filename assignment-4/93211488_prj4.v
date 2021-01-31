module fp_adder
    (
        input [31:0] a,
        input [31:0] b,
        output [31:0] s
    );
	wire s1, s2;
	wire [7:0] e1, e2, corrected_e1, corrected_e2, max_exp;
	wire [22:0] f1, f2;
	wire [23:0] complete_f1, complete_f2; 
	wire [26:0] op1, op2;
	wire [27:0]	sum;
	
	assign {s1, e1, f1} = a;
	assign {s2, e2, f2} = b; 
	
	assign corrected_e1 = (e1 == 8'b0)? 8'b1 : e1;
	assign corrected_e2 = (e2 == 8'b0)? 8'b1 : e2;
	
	wire borrow, add_sub;
	
	assign borrow = (corrected_e1 < corrected_e2);
	
	assign complete_f1 = (e1 == 8'b0)? {1'b0, f1} : {1'b1, f1};
	assign complete_f2 = (e2 == 8'b0)? {1'b0, f2} : {1'b1, f2};
	
	assign max_exp = (borrow)? corrected_e2 : corrected_e1;
	//assign min_exp = (borrow)? corrected_e1 : corrected_e2;
	
	assign add_sub = (s1 ^ s2);//0 for ADD, 1 for SUB
	
	assign op1 = (borrow)?{complete_f2, 3'b0}:(corrected_e1 != corrected_e2)?{complete_f1, 3'b0}:(complete_f1 > complete_f2)? {complete_f1, 3'b0} : {complete_f2, 3'b0};
	
	barrel_shifter bsu
	(
	corrected_e1,
	corrected_e2,
	(borrow)?complete_f1:(corrected_e1 != corrected_e2)?complete_f2:(complete_f1 > complete_f2)? complete_f2: complete_f1,
	borrow,
	op2
	);
	
	assign sum = (add_sub)? op1 - op2:op1 + op2;
	
	wire [24:-3] n1_frac, rounded_frac;
	wire [-1:-23] n2_frac;
	wire [7:0] n1_exp, n2_exp;
	
	normalizer n1 (
		sum,
		max_exp,
		n1_frac,
		n1_exp
	);
	
	rounder ru(
	n1_frac,
	rounded_frac
	);
	
	wire sign_s = (s1 && s2) || ((!s1 && s2) && (corrected_e1 < corrected_e2 || (corrected_e1 == corrected_e2 && complete_f1 < complete_f2))) || ((s1 && !s2) && (corrected_e1 > corrected_e2 || (corrected_e1 == corrected_e2 && complete_f1 > complete_f2)));
	
	/*normalizer n2(
		rounded_frac,
		n1_exp,
		n2_frac,
		n2_exp
	);
	wire [-1:-23] s_frac = n2_frac[-1:-23];
	wire [7:0] s_exp = (n2_frac[0])?n2_exp:8'd0;
	assign s = {sign_s, s_exp, s_frac};*/
	
	norm2 n2(
		rounded_frac,
		n1_exp,
		n2_frac,
		n2_exp
	);
	
	assign s = {sign_s, n2_exp, n2_frac};
	
endmodule	
module barrel_shifter
(
	e1,
	e2,
	frac_in,
	borrow,
	frac_out
);
	input [7:0] e1, e2;
	input borrow;
	input [23:0] frac_in;
	output [26:0] frac_out;
	
	wire [7:0] diff;
	wire [4:0] shift_amount;
	wire [23:-28] pre_shift, post_shift;
	
	assign diff = (borrow)? e2 - e1 : e1 - e2;
	assign shift_amount = (diff > 26)? 5'd26:diff;
	
	assign pre_shift = {frac_in, 28'b0};
	assign post_shift = (pre_shift >> shift_amount);
	assign frac_out [26:1] = post_shift[23:-2];
	assign frac_out [0] = |(post_shift[-3:-28]);
	
endmodule	
module normalizer(
	frac_in,
	exp_in,
	frac_out,
	exp_out
);
	input [1:-26] frac_in;
	input [7:0] exp_in;
	output [24:-3] frac_out;
	output [7:0] exp_out;
	
	wire signed [5:0] shift_amount;
	
	exp_generator eg(
	exp_in,
	frac_in,
	shift_amount,
	exp_out
);
	assign frac_out =(shift_amount == -1)?{1'b0, frac_in[1:-24], |(frac_in[-25:-26])}:(shift_amount == 0)? frac_in :( frac_in << (shift_amount));
endmodule

module norm2(
	frac_in,
	exp_in,
	frac_out,
	exp_out
);
	input [1:-26] frac_in;
	input [7:0] exp_in;
	wire [1:-26]s_frac;
	output [-1:-23] frac_out;
	output [7:0] exp_out;
	
	assign s_frac = (frac_in[1])?{1'b0, frac_in[1:-24], |(frac_in[-25:-26])}:frac_in;
	assign frac_out = s_frac[-1:-23];
	assign exp_out = (frac_in[1])?exp_in + 1:(frac_in[0])?exp_in:8'b0;
endmodule

module exp_generator(
	exp_in,
	frac_in,
	shift_amount,
	exp_out
);
	input [7:0] exp_in;
	input [1:-26] frac_in;
	output [7:0] exp_out;
	output signed [5:0] shift_amount;
	
	wire signed [5:0]x[1:-27];
	
	genvar cnt;
	assign x[-27] = {1'b0, (~5'd0)};
	generate
		for (cnt = -26; cnt <= 1; cnt = cnt + 1)begin:oring
			assign x[cnt] = (frac_in[cnt])? (-cnt):x[cnt - 1];
		end
	endgenerate
	assign shift_amount = ( $signed({1'b0, exp_in}) - 1 < x[1])?$signed({1'b0, exp_in}) - 1:x[1];
	
	assign exp_out = ( /*$signed({1'b0, exp_in}) < shift_amount ||*/ frac_in == 28'b0)? 8'd0:  exp_in - {{2{shift_amount[5]}},shift_amount};
endmodule	
module rounder(
	frac_in,
	frac_out
);
	input [24:-3] frac_in;
	output [24:-3] frac_out; 
	
	wire [-1:-3] x = frac_in[-1:-3];
	//wire [24:-3] inter = {1'b0, frac_in};
	
	assign frac_out = (x < 3'b100)?  frac_in : (x > 3'b100)? {frac_in[24:0] + 1'b1, 3'b0}:(frac_in[0])?{frac_in[24:0] + 1'b1, 3'b0}:{ frac_in[24:0], 3'b0};

endmodule