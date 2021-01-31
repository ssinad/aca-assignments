`timescale 1ns/10ps

`define ADD 0 
`define SUB 1
`define AND 2
`define OR 3
`define NOR 4
`define XOR 5
`define SLT 6
`define SLTU 7

module single_cycle_mips(
	clk,
	reset
	);
	input clk, reset;
	
	reg [31:0] /*A, B,*/ pc, /*IR, MDR, MAR,*/ aluB, WD;
	reg [4:0] WR;
	wire /*PCwrt, IRwrt, MARwrt,*/ se_ze, signed_mul, mult_start, zero, /*alusrcB, IorD,*/ memwrt, regwrt;//, Awrt, Bwrt;
	wire [31:0] alu_result, RD1, RD2, RD, hi, lo;
	wire [1:0] PCsrc, regDst, alusrcB;
	wire [2:0] regDataSel;
	wire [3:0] aluOp;
	wire [31:0] instr;
	
	wire [31:0] imm_32 = se_ze ? {{16{instr[15]}},instr[15:0]}: {16'b0, instr[15:0]};
	wire [31:0] next_pc = pc + 32'd4;
	
	always @(posedge clk)
	begin:PC_always
		if (reset)
			pc <= #0.1 32'b0;
		else
			case(PCsrc)
				2'b00: pc <= #0.1 next_pc;
				2'b01: pc <= #0.1 {next_pc[31:28], instr[25:0], 2'b0};
				2'b10: pc <= #0.1 RD1;
				2'b11: pc <= #0.1 next_pc + (imm_32 << 2);
				default: pc <= 32'bx;
			endcase
	end
	
	always @(*)
	begin
		case (regDst)
		2'b00:
			WR = instr[20:16];//instr[15:11];
		2'b01:
			WR = instr[15:11];//instr[20:16];
		2'b10:
			WR = 5'd31;
		default:
			WR = 5'bx;
		endcase
	end
	
	always @(*)
	begin
		case (regDataSel)
		3'b000:
			WD = next_pc;//alu_result;
		3'b001:
			WD = hi;
		3'b010:
			WD = lo;
		3'b011:
			WD = alu_result;//{instr[15:0], 16'b0};
		3'b100:
			WD = {instr[15:0], 16'b0};//pc;
		3'b101:
			WD = RD;	//Load		
		default:
			WD = 32'bx;
		endcase
	end

	reg_file rf(
   .clk(clk),
   .write(regwrt),
   .WR(WR),
   .WD(WD),
   .RR1(instr[25:21]),
   .RR2(instr[20:16]),
   .RD1(RD1),
   .RD2(RD2)
	);

	async_mem data_mem(
   .clk(clk),
   .write(memwrt),
   .address(alu_result),
   .write_data(RD2),
    .read_data(RD)
	);
	
	async_mem inst_mem(
   .clk(),
   .write(1'b0),
   .address(pc),
   .write_data(),
    .read_data(instr)
	);
	
	always @(*)
	begin
		case(alusrcB)
		2'b0: aluB = RD2;
		2'b1: aluB = imm_32;
		//2'd2 : aluB = imm_32 << 2; 
		endcase
	end
	
	my_alu alu(
   .aluA(RD1),
   .aluB(aluB),
   .aluOp(aluOp),
   .aluResult(alu_result),
   .aluZero(zero)
);
	multiplier mul(
    .clk(clk),            // module clock, everything should be done in positive edge of it
    .start(mult_start),          // indicates all inputs are valid and multiplication should be started
    .is_signed(signed_mul),      // when 1, signed multiplication is intended, otherwise, it's unsigned
    .a(RD1),   // first operand,
    .b(RD2),   // second operand
    .s({hi, lo})   // output result
    );
	
	processor_ctrl pctrl(
	.clk(clk), 
	.reset(reset),
	.zero(zero),
	.Opcode(instr[31:26]),
	.funct(instr[5:0]), 
	.se_ze(se_ze),
	.signed_mul(signed_mul),
	.mult_start(mult_start),
	.alusrcB(alusrcB),
	.memwrt(memwrt),
	.regwrt(regwrt),
	.PCsrc(PCsrc),
	.regDst(regDst),
	.regDataSel(regDataSel),
	.aluOp(aluOp)
);
endmodule

module processor_ctrl(
	clk, 
	reset,
	zero,
	Opcode,
	funct, 
	se_ze,
	signed_mul,
	mult_start,
	alusrcB,
	memwrt,
	regwrt,
	PCsrc,
	regDst,
	regDataSel,
	aluOp
);
	//localparam fetch1 = 0, fetch2 = 1, fetch3 = 2, ldreg = 3, exec = 4, ls = 5, lw1 = 6, lw2 = 7, lw3 = 8, sw1 = 9, sw2 = 10,  mult_st = 11, mult_count = 12, branch_calc = 13, branch_decision = 14;
	localparam Undefined = 'bx, ArithLog = 0, ArithLogI = 1, LoadStore = 2, Branch = 3, Jump = 4, Multiply = 5, Move = 6, LUI = 7;
	localparam 
	add	= 6'b100000   ,
	addu = 6'b100001 ,
	addi  = 6'b001000,
	addiu = 6'b001001,
	and_op = 6'b100100  ,
	andi = 6'b001100 ,
	mult = 6'b011000 ,
	multu = 6'b011001,
	nor_op = 6'b100111  ,
	or_op = 6'b100101   ,
	ori = 6'b001101  ,
	sub = 6'b100010  ,
	subu = 6'b100011 ,
	xor_op = 6'b100110  ,
	xori = 6'b001110 ,
	slt = 6'b101010  ,
	sltu = 6'b101011 ,
	slti = 6'b001010 ,
	sltiu = 6'b001001,
	beq = 6'b000100  ,
	bne = 6'b000101  ,
	j = 6'b000010    ,
	jal = 6'b000011  ,
	jalr = 6'b001001 ,
	jr = 6'b001000   ,
	lw = 6'b100011   ,
	sw = 6'b101011   ,
	mfhi = 6'b010000 ,
	mflo = 6'b010010  ,
	lui = 6'b001111;
	
	input clk, reset, zero;
	input [5:0] Opcode;
	input [5:0] funct;
	
	output reg se_ze, signed_mul, mult_start, memwrt, regwrt;
	output reg [1:0] PCsrc, regDst, alusrcB;
	output reg [2:0] regDataSel;
	output reg [3:0] aluOp;
	
	reg [3:0] instr_type;
	
	always @(*)
	begin
		instr_type = Undefined;
		case (Opcode)
			6'b0:
				case (funct)
				jr :
					instr_type = Jump;
				jalr:
					instr_type = Jump;
				mfhi:
					instr_type = Move;
				mflo :
					instr_type = Move;
				mult:
					instr_type = Multiply;
				multu:
					instr_type = Multiply;
				add:
					instr_type = ArithLog;
				sub:
					instr_type = ArithLog;
				addu:
					instr_type = ArithLog;
				subu:
					instr_type = ArithLog;
				and_op:
					instr_type = ArithLog;
				or_op:
					instr_type = ArithLog;
				xor_op:
					instr_type = ArithLog;
				nor_op:
					instr_type = ArithLog;
				slt:
					instr_type = ArithLog;
				sltu:
					instr_type = ArithLog;
				endcase
			addiu:
				instr_type = ArithLogI;
			slti:                    
				instr_type = ArithLogI;
			sltiu:                   
				instr_type = ArithLogI;
			andi:                    
				instr_type = ArithLogI;
			ori:                     
				instr_type = ArithLogI;
			xori:
				instr_type = ArithLogI;
			addi :
				instr_type = ArithLogI;
			beq  :
				instr_type = Branch;
			bne  :
				instr_type = Branch;
			j  :
				instr_type = Jump;
			jal  :
				instr_type = Jump;
			lui:
				instr_type = LUI;
			lw:
				instr_type = LoadStore;
			sw:
				instr_type = LoadStore;
		endcase
	end
	
	always @(*)
	begin
		se_ze = 1'bx; signed_mul = 1'bx; mult_start = 1'b0; memwrt = 1'b0; regwrt = 1'b0;   
		PCsrc = 2'bx; alusrcB = 2'bx; regDst = 2'bx;
		regDataSel = 3'bx;
		aluOp = 4'bx;
		case (instr_type)
		ArithLog:
		begin
			PCsrc = 1'b0;
			regDataSel = 3'b011;
			regDst = 2'b01;
			regwrt = 1'b1;
			alusrcB = 0;
			
			case (funct)
			add: aluOp = `ADD;
			addu: aluOp = `ADD;
			sub: aluOp = `SUB;
			subu: aluOp = `SUB;
			and_op: aluOp = `AND;
			or_op: aluOp = `OR;
			xor_op: aluOp = `XOR;
			nor_op: aluOp = `NOR;
			slt: aluOp = `SLT;
			sltu: aluOp = `SLTU;
			endcase
				
		end
		ArithLogI:
		begin
			PCsrc = 1'b0;
			regDataSel = 3'b011;
			regDst = 2'b0;
			regwrt = 1'b1;
			alusrcB = 1;
			
			case (Opcode)
			addi:  begin  aluOp = `ADD;    se_ze = 1; end
			addiu: begin   aluOp = `ADD;   se_ze = 1; end
			andi:  begin  aluOp = `AND;    se_ze = 0; end
			ori:   begin   aluOp = `OR;    se_ze = 0; end
			xori:  begin  aluOp = `XOR;    se_ze = 0; end
			slti:  begin  aluOp = `SLT;     se_ze = 1; end
			sltiu: begin  aluOp = `SLTU;   se_ze = 0; end
			endcase
		end
		LoadStore:
		begin
			PCsrc = 0;
			aluOp = `ADD;
			alusrcB = 1;
			se_ze = 1;
			case (Opcode)
			lw:
			begin
				regwrt = 1'b1;
				regDataSel = 3'b101;
				regDst = 0;
			end
			sw:
			begin
				memwrt = 1'b1;
			end
			endcase
		end
		Branch:
		begin
			PCsrc = (Opcode == beq && zero) || (Opcode == bne && !zero)?2'b11:2'b0;
			aluOp = `SUB;
			alusrcB = 0;
			se_ze = 1;
		end
		Jump:
		begin
			case (Opcode)
				6'b0:
				begin
					PCsrc = 2'b10;
					case (funct)
					//jr:
					jalr:
					begin
						regwrt = 1'b1;
						regDst = 2'b10;
						regDataSel = 3'b0;
					end
					endcase
				end
				j:
					PCsrc = 2'b1;
				jal:
				begin
					PCsrc = 2'b1;
					regwrt = 1'b1;
					regDst = 2'b10;
					regDataSel = 3'b0;
				end
			endcase
		end
		Multiply:
		begin
			PCsrc = 0;
			mult_start = 1'b1;
			case (funct)
			mult:
				signed_mul = 1;
			multu:
				signed_mul = 0;
			endcase
		end
		Move:
		begin
			PCsrc = 1'b0;
			regwrt = 1'b1;
			case(funct)
			mfhi:
			begin
				regDataSel = 3'b001;
				regDst = 2'b1;
			end
			mflo:
			begin
				regDataSel = 3'b010;
				regDst = 2'b1;
			end
			endcase
		end
		LUI:
		begin
			PCsrc = 1'b0;
			regDataSel = 3'b100;
			regDst = 2'b0;
			regwrt = 1'b1;
		end
		endcase
		/*case (current_state)
			fetch1:
				IorD = 1'b0;
			fetch2:
				IorD = 1'b0;
			fetch3:
			begin
				IorD = 1'b0;
				IRwrt = 1'b1;
				alusrcA = 1; 
				alusrcB = 1;
				aluOp = `ADD;
				PCwrt = 1'b1;
				PCsrc = 0;
			end
			ldreg:
			begin
				Awrt = 1'b1;
				Bwrt = 1'b1;
				case (instr_type)
					Jump: 
					begin
					PCwrt = 1'b1;
						case (Opcode)
						j:
							PCsrc = 2'b1;
						jal:
						begin
							PCsrc = 2'b1;
							regwrt = 1'b1;
							regDst = 2'd2;
							regDataSel = 3'b0;
						end
						default:
							case(funct)
							jr:
								PCsrc = 2'd2;
							jalr:
							begin
								PCsrc = 2'd2;
								regDst = 2'b1;
								regwrt = 1'b1;
								regDataSel = 3'b0;
							end
							endcase
						endcase
					end
					Move: 
					begin
						regwrt = 1'b1;
						regDst = 2'b1;
						case (funct)
						mfhi:
							regDataSel = 3'd1;
						mflo:
							regDataSel = 3'd2; 
						endcase
					end
					LUI: 
					begin
						regwrt = 1'b1;
						regDst = 2'b0;
						regDataSel = 3'd4;
					end
					//default:	
				endcase
			end
			exec:
			begin
				regwrt = 1'b1;
				case (instr_type)
					ArithLog:
					begin
						alusrcA = 0;
						alusrcB = 0;
						regDst = 2'b1;
					end
					ArithLogI:
					begin
						regDst = 2'b0;
						alusrcA = 0;
						alusrcB = 2;
					end
				endcase
				regDataSel = 3'd3;
				case (Opcode)
					6'b0:
					case (funct)
					add: aluOp = `ADD;
					addu: aluOp = `ADD;
					sub: aluOp = `SUB;
					subu: aluOp = `SUB;
					and_op: aluOp = `AND;
					or_op: aluOp = `OR;
					xor_op: aluOp = `XOR;
					nor_op: aluOp = `NOR;
					slt: aluOp = `SLT;
					sltu: aluOp = `SLTU;
					endcase
					addi:  begin  aluOp = `ADD;    se_ze = 1; end
					addiu: begin   aluOp = `ADD;   se_ze = 1; end
					andi:  begin  aluOp = `AND;    se_ze = 0; end
					ori:   begin   aluOp = `OR;    se_ze = 0; end
					xori:  begin  aluOp = `XOR;    se_ze = 0; end
					slti:  begin  aluOp = `SLT;     se_ze = 1; end
					sltiu: begin  aluOp = `SLTU;   se_ze = 0; end
				endcase    
			end            
			ls:            
			begin
				aluOp = `ADD;
				alusrcA = 0; 
				alusrcB = 2;
				MARwrt = 1'b1;
				se_ze = 1;
			end
			branch_calc:
			begin
				aluOp = `SUB;
				alusrcA = 0; 
				alusrcB = 0;
			end
			branch_decision:
			begin
				aluOp = `ADD;
				alusrcA = 1; 
				alusrcB = 3;
				se_ze = 1;
				PCwrt = 1'b1;
				PCsrc = 0;
			end	
			lw1:
				IorD = 1;
			lw2:
				IorD = 1;
			lw3:
			begin
				IorD = 1;
				regwrt = 1'b1;
				regDst = 0;
				regDataSel = 5;
			end
			sw1:
			begin
				IorD = 1;
				memwrt = 1;
			end
			//sw2:	
			mult_st:
			begin
				mult_start = 1;
				case (funct)
					mult:
						signed_mul = 1;
					multu:
						signed_mul = 0;
				endcase
			end
			
		endcase*/
	end
	
endmodule

module my_alu(
   input [31:0] aluA,
   input [31:0] aluB,
   input [3:0] aluOp,

   output reg [31:0] aluResult,
   output        aluZero
);
   always @(*)
      case(aluOp)
        `ADD : #2  aluResult =  aluA + aluB;           // add
        `SUB : #2  aluResult =  aluA + ~aluB + 1'b1;      // sub
        `AND : #2  aluResult =  aluA & aluB;
        `OR  : #2  aluResult =  aluA | aluB;
        `NOR : #2  aluResult =   ~( aluA | aluB );//aluA ~| aluB;    // ?? ~ ( aluA | aluB )
        `XOR : #2  aluResult =  aluA ^ aluB;
        `SLT : #2  aluResult =  $signed(aluA) < $signed(aluB)? 32'b1:32'b0;
		`SLTU :#2  aluResult =  $unsigned(aluA) < $unsigned(aluB)? 32'b1:32'b0;
		default:
		aluResult = 'bx;
      endcase

   assign aluZero = ~(|aluResult);

endmodule

module async_mem(
   input clk,
   input write,
   input [31:0] address,
   input [31:0] write_data,
   output [31:0] read_data
);


   reg [31:0] mem_data [0:1023];

   assign #7 read_data = mem_data[ address[31:2] ];

   always @(posedge clk)
      if(write)
         mem_data[ address[31:2] ] <= #2 write_data;

endmodule

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

   reg [31:0] rf_data [0:31];

   assign #2 RD1 = rf_data[ RR1 ];

   assign #2 RD2 = rf_data[ RR2 ];

   always @(posedge clk) begin
      if(write) begin
         rf_data[ WR ] <= #0.1 WD;

         `ifdef DEBUG
         if(WR)
            $display("$%0d = %x", WR, WD);
         `endif

      end
      rf_data[0] <= #0.1 32'h00000000;
   end

endmodule	
module multiplier (
        input clk,            // module clock, everything should be done in positive edge of it
        input start,          // indicates all inputs are valid and multiplication should be started
        input is_signed,      // when 1, signed multiplication is intended, otherwise, it's unsigned
        input [31 : 0] a,   // first operand,
        input [31 : 0] b,   // second operand
        output [63 : 0] s   // output result
    );
	parameter n = 32;
	reg [2 * n - 1:0] prod;
	//input clk, arst;
	assign s = prod;
	always @(posedge clk)
	begin
		if (start)
			prod <= #0.1 (is_signed)? $signed(a) * $signed(b) : $unsigned(a) * $unsigned(b);
	end
	
endmodule