//===========================================================
//
//			Name & Student ID
//
//			Implemented Instructions are:
//			R format:     addu, subu, and, or, xor, nor, slt, sltu;
//			I & J format: j, beq, bne, lw, sw, addiu, slti, sltiu, andi, ori, xori, lui.
//
//===========================================================

`define DEBUG	// comment this line to disable register content writing below

`timescale 1ns/1ps

module pipelined_mips 
(
	input clk,
	input reset
);
 
	initial begin
		$display("Pipelined MIPS Implemention");
		$display("Name & Student ID");
	end

	
	
	// Data & Control path
	
	
	
//========================================================== 
//	instantiated modules
//========================================================== 

//	Instruction Memory
	async_mem instr_mem			// keep the exact instance name
	(
		.clk		(clk),
		.write		('b0),	// no write for instruction memory
		.address	(pc),	// address instruction memory with pc
		.write_data	('bx),
		.read_data	(instr_rd)
	);
	
//	Register File
	reg_file rf			// keep the exact instance name
	(
		.clk	(clk),
		.write	(rf_write),
		.WR		(rf_wr),
		.WD		(rf_wd),
		.RR1	(ir_r[25:21]),
		.RR2	(ir_r[20:16]),
		.RD1	(rf_rd1),
		.RD2	(rf_rd2)
	);	
	
// Data Memory
	async_mem data_mem		// keep the exact instance name
	(
		.clk		(clk),
		.write		(dm_write),
		.address	(dm_address),
		.write_data	(dm_write_data),
		.read_data	(dm_read_data)
	);

// Arithmatic and Logic Unit (ALU)	
	ALU alu
	(
		.ALU_A		(alu_a),
		.ALU_B		(alu_b),
		.ALU_OP		(alu_op),
		.ALU_Result	(alu_result),
		.ALU_Zero	(alu_zero)
	);

	
endmodule

//========================================================== 
//	end of main module
//========================================================== 

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

	reg [31:0] reg_data [0:31];

	assign RD1 = ((RR1==WR)&&write)? WD : reg_data[ RR1 ];
	assign RD2 = ((RR2==WR)&&write)? WD : reg_data[ RR2 ];

//	assign RD1 = reg_data[ RR1 ];
//	assign RD2 = reg_data[ RR2 ];
	
	always @(posedge clk) begin
		if(write) begin
			reg_data[ WR ] <= #1 WD;

			`ifdef DEBUG
			if(WR)
				$display("$%0d = %x", WR, WD);
			`endif
		end
		reg_data[0] <= #1  32'h00000000;
	end

endmodule

module async_mem(
	input clk,
	input write,
	input [31:0] address,
	input [31:0] write_data,
	output [31:0] read_data
);

	reg [31:0] mem_data [0:1023];

	assign read_data = mem_data[ address[31:2] ];

	always @(posedge clk)
		if(write)
			mem_data[ address[31:2] ] <= #1 write_data;

endmodule
