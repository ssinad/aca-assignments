`timescale 1ns/1ps

`define ADD 0 
`define SUB 1
`define AND 2
`define OR 3
`define NOR 4
`define XOR 5
`define SLT 6
`define SLTU 7

`define R_format 1
`define Load 2
`define Branch 3
`define Jump 4
`define LUI 5
`define Immediate 6
`define Store 7
`define JumpRegister 8
`define JumpAndLinkRegister 9 
`define Link 0
`define BranchIfEqual 10
`define BranchIfNotEqual 11

module pipelined_mips(
	clk,
	reset
	);
	input clk, reset;
	
	/*reg [31:0] /*A, B, pc, IR, MDR, MAR, aluB, WD;
	reg [4:0] WR;
	wire PCwrt, IRwrt, MARwrt, se_ze, signed_mul, mult_start, zero, alusrcB, IorD, memwrt, regwrt;//, Awrt, Bwrt;
	wire [31:0] alu_result, RD1, RD2, RD, hi, lo;
	wire [1:0] PCsrc, regDst;
	wire [2:0] regDataSel;
	wire [3:0] aluOp;
	wire [31:0] instr;*/
	
	wire [31:0] next_pc_ex, next_pc_mem, ui_ex, ui_mem, alu_result_mem, next_pc_if, instr_if, branch_pc_id2if, jump_pc_id2if, WD_wb2rf, RD1_id;
	wire flush, PCwrt;
	wire [3:0] PCsrc;
	
	IF_stage if_inst
	(
		.clk(clk),
		.reset(reset),
		.flush(flush),
		.PCsrc(PCsrc),
		.RD1_id(RD1_id),
		//.RD1_ex,
		.RD1_mem_alu(alu_result_mem),
		.RD1_wb(WD_wb2rf),
		.branch_pc_id(branch_pc_id2if),
		.jump_pc_id(jump_pc_id2if),
		.instr(instr_if),
		.next_pc_if(next_pc_if),
		//.next_pc_id,
		.next_pc_ex(next_pc_ex),
		.next_pc_mem(next_pc_mem),
		//.ui_id,
		.ui_ex(ui_ex),
		.ui_mem(ui_mem),
		.PCwrt(PCwrt)
	);
	
	wire [31:0] instr_id, next_pc_id;
	wire [3:0] instr_type_id, instr_type_ex, instr_type_mem;//, instr_type_wb;
	
	IF_ID if_id_reg
	(
		.clk(clk),
		.reset(reset),
		.next_pc_if(next_pc_if),
		.next_pc_id(next_pc_id),
		.instr_if(instr_if),
		.instr_id(instr_id),
		.stall(stall)
	);
	
	wire[31:0] imm_32_id, RD1_thru, RD2_thru, ui_id;
	wire [4:0] WR_wb2rf, WR_id, WR_ex, WR_mem, SR1_id, ALUsr1_ex, SR2_id, ALUsr2_ex, /*STSr_id, STSr_ex,*/ STSr_mem;
	wire [1:0] regDst; 
	wire se_ze, equal, rd1_write_thru, rd2_write_thru;
	wire [2:0] branchR1src, branchR2src;
	
	ID_stage id_inst                                                        
	(                                                              
		.clk(clk),                                                 
		.instr(instr_id),                                          
		.WD_wb2rf(WD_wb2rf),                                       
		.regDst(regDst),                                           
		.regwrt(regwrt_wb),                                        
		.WR_id(WR_id),                                             
		.WR_wb2rf(WR_wb2rf),                                       
		.se_ze(se_ze),                                             
		.branchR1src(branchR1src),                                 
		.branchR2src(branchR2src),                                 
		.RD_mem_alu(alu_result_mem),                               
		//.RD_wb,                                                  
		.rd1_write_thru(rd1_write_thru),                           
		.rd2_write_thru(rd2_write_thru),                           
		.RD1(RD1_thru),                                            
		.RD2(RD2_thru),                                            
		//.regDst,                                                 
		.equal(equal),                                             
		.SR1(SR1_id),                                              
		.SR2(SR2_id),                                              
		//.STSr(STSr_id),                                          
		.imm_32(imm_32_id),                                        
		//.WR_wb2rf,                                               
		.ui_ex(ui_ex),                                             
		.next_pc_ex(next_pc_ex),                                   
		.next_pc(next_pc_id),                                      
		.ui_mem(ui_mem),                                           
		.next_pc_mem(next_pc_mem),                                 
		.branch_pc(branch_pc_id2if),                               
		.RD1_id(RD1_id),                                           
		.ui_id(ui_id),
		.jump_pc(jump_pc_id2if)		
	);
	
	wire [31:0] imm_32_ex, RD1_ex, RD2_ex;
	wire [3:0] aluOp_ex, aluOp_id;
	wire [1:0] regDataSel_id, regDataSel_ex, regDataSel_mem, regDataSel_wb;
	
	ID_EX id_ex_reg
	(
		.clk(clk),                                             
		.reset(reset),                                         
		.aluR1_id(SR1_id),                                     
		.aluR2_id(SR2_id),                                     
		.aluR1_ex(ALUsr1_ex),                                  
		.aluR2_ex(ALUsr2_ex),                                  
		.imm_32_id(imm_32_id),                                 
		.imm_32_ex(imm_32_ex),                                 
		//.STR_id(STSr_id),                                    
		//.STR_ex(STSr_ex),                                    
		.WR_id(WR_id),                                         
		.WR_ex(WR_ex),                                         
		.RD1_thru_id(RD1_thru),                                
		.RD2_thru_id(RD2_thru),                                
		.RD1_ex(RD1_ex),                                       
		.RD2_ex(RD2_ex),                                       
		.next_pc_id(next_pc_id),                               
		.next_pc_ex(next_pc_ex),                               
		.ui_id(ui_id),                                         
		.ui_ex(ui_ex),                                         
		.aluOp_id(aluOp_id),                                   
		.aluOp_ex(aluOp_ex),  
		.instr_type_id(instr_type_id),
		.instr_type_ex(instr_type_ex),
		.regwrt_id(stall?1'b0:regwrt_ctrl),
		.regwrt_ex(regwrt_ex),
		.memwrt_id(stall?1'b0:memwrt_ctrl),
		.memwrt_ex(memwrt_ex),
		.regDataSel_id(regDataSel_id),
		.regDataSel_ex(regDataSel_ex)
	);                                                         
	                                                           
	wire [31:0]  alu_result_ex;  
	wire [2:0] alusrcA, alusrcB;                               
	                                                           
	EX_stage ex_inst
	(
		.RD1(RD1_ex),
		.RD_mem_alu(alu_result_mem),
		.RD_mem_next_pc(next_pc_mem),
		.RD_mem_ui(ui_mem),
		.RD_wb(WD_wb2rf),
		.RD2(RD2_ex),
		.alusrcA(alusrcA),
		.alusrcB(alusrcB),
		.imm_32(imm_32_ex),
		.aluOp(aluOp_ex),
		.alu_result(alu_result_ex)
	);
	
	//input [4:0]  WR_mem;
	wire [31:0] RD2_mem;
	
	EX_MEM ex_mem_reg
	(
		.clk(clk),
		.reset(reset),
		.alu_result_ex(alu_result_ex),
		.alu_result_mem(alu_result_mem),
		.STR_ex(ALUsr2_ex),
		.STR_mem(STSr_mem),
		.next_pc_ex(next_pc_ex),
		.next_pc_mem(next_pc_mem),
		.ui_ex(ui_ex),
		.ui_mem(ui_mem),
		.RD2_ex(RD2_ex),
		.RD2_mem(RD2_mem),
		.memwrt_ex(memwrt_ex),
		.memwrt_mem(memwrt_mem),
		.WR_ex(WR_ex),
		.WR_mem(WR_mem),
		.regwrt_ex(regwrt_ex),
		.regwrt_mem(regwrt_mem),
		.instr_type_ex(instr_type_ex),
		.instr_type_mem(instr_type_mem),
		.regDataSel_ex(regDataSel_ex),
		.regDataSel_mem(regDataSel_mem)
	);
	wire [31:0] memRD_mem, memRD_wb;
	wire memWrtSrc;
	MEM_stage mem_inst
	(
		.clk(clk),
		.memwrt(memwrt_mem),
		.memWrtSrc(memWrtSrc),
		.RD2(RD2_mem),
		.alu_result(alu_result_mem),
		//.RDf_mem_alu(),
		.memRD(memRD_mem),
		.RD2_wb(WD_wb2rf)
	);
	
	wire [31:0] ui_wb, next_pc_wb, alu_result_wb;
	//wire [3:0] regDataSel_mem, regDataSel_wb;
	MEM_WB mem_wb_reg
	(
		.clk(clk),
		.reset(reset),
		.alu_result_wb(alu_result_wb),
		.alu_result_mem(alu_result_mem),
		.memRD_mem(memRD_mem),
		.memRD_wb(memRD_wb),
		.next_pc_wb(next_pc_wb),
		.next_pc_mem(next_pc_mem),
		.regDataSel_mem(regDataSel_mem),
		.regDataSel_wb(regDataSel_wb),
		.ui_mem(ui_mem),
		.ui_wb(ui_wb),
		.WR_mem(WR_mem),
		.WR_wb(WR_wb2rf),
		.regwrt_mem(regwrt_mem),
		.regwrt_wb(regwrt_wb)
	);
	
	WB_stage wb_inst
	(
	.next_pc(next_pc_wb),
	.alu_result(alu_result_wb),
	.ui(ui_wb),
	.regDataSel(regDataSel_wb),
	.memRD(memRD_wb),
	.WD(WD_wb2rf)
	);
	
	sc_ctrl pctrl(
	.clk(clk), 
	.reset(reset),
	//.zero(zero),
	.Opcode(instr_id[31:26]),
	.funct(instr_id[5:0]), 
	.se_ze(se_ze),
	//.signed_mul(signed_mul),
	//.mult_start(mult_start),
	//.alusrcB(alusrcB),
	.memwrt(memwrt_ctrl),
	.regwrt(regwrt_ctrl),
	//.PCsrc(PCsrc),
	.regDst(regDst),
	.regDataSel(regDataSel_id),
	.aluOp(aluOp_id),
	.WBinstr_type(instr_type_id)
);

	HazardHandler hazard_handler_inst
	(
		.instr_type_id(instr_type_id),
		.instr_type_ex(instr_type_ex),
		.instr_type_mem(instr_type_mem),
		//.instr_type_wb,
		.WR_id(WR_id),
		.WR_ex(WR_ex),
		.WR_mem(WR_mem),
		.WR_wb(WR_wb2rf),
		//.STSr_id,
		.SR1_id(SR1_id),
		.SR2_id(SR2_id),
		//.STSr_ex,
		.ALUsr1_ex(ALUsr1_ex),
		.ALUsr2_ex(ALUsr2_ex),
		.STSr_mem(STSr_mem),
		.regwrt_ex(regwrt_ex),
		.regwrt_mem(regwrt_mem),
		.regwrt_wb(regwrt_wb),
		.alusrcA(alusrcA),
		.alusrcB(alusrcB),
		.branchR1src(branchR1src),
		.branchR2src(branchR2src),
		.PCsrc(PCsrc),
		.memWrtSrc(memWrtSrc), 
		.rd1_write_thru(rd1_write_thru), 
		.rd2_write_thru(rd2_write_thru),
		.equal(equal),
		.stall(stall),
		.PCwrt(PCwrt),
		.flush(flush)
	);                  
endmodule

//Responsible for Data Forwarding and Stalls
module HazardHandler
(
	instr_type_id,
	instr_type_ex,
	instr_type_mem,
	//instr_type_wb,
	WR_id,
	WR_ex,
	WR_mem,
	WR_wb,
	//STSr_id,
	SR1_id,
	SR2_id,
	//STSr_ex,
	ALUsr1_ex,
	ALUsr2_ex,
	STSr_mem,
	regwrt_ex,
	regwrt_mem,
	regwrt_wb,
	alusrcA,
	alusrcB,
	branchR1src,
	branchR2src,
	PCsrc,
	memWrtSrc, 
	rd1_write_thru, 
	rd2_write_thru,
	equal,
	stall,
	PCwrt,
	flush
);                                                                     
    input equal;
	input [3:0] instr_type_id, instr_type_ex, instr_type_mem;//, instr_type_wb;
	input [4:0] WR_id, WR_ex, WR_mem, WR_wb, SR1_id, SR2_id, ALUsr1_ex, ALUsr2_ex, STSr_mem;
	input regwrt_ex, regwrt_mem, regwrt_wb;
	output reg [2:0] alusrcA, alusrcB, branchR1src, branchR2src;    
	output reg memWrtSrc, rd1_write_thru, rd2_write_thru, stall, flush;	               
	output reg [3:0] PCsrc;                                                             
	output PCwrt;                                                                       
	                                                                                    
	assign PCwrt = !stall;                                                              
	                                                                                    
	always @(*)                                                                         
	begin                                                                               
		stall = 1'b0;                                                                   
		if (regwrt_ex && (WR_ex == SR1_id || WR_ex == SR2_id) && WR_ex != 5'b0)                          
		case (instr_type_ex)                                                            
		`Load:	                                                                        
			case (instr_type_id)                                                        
				`R_format,                                                           
				`BranchIfEqual,                                                      
				`BranchIfNotEqual:                                                   
					stall = 1'b1;                                                    
				`Immediate,                                                          
				`JumpRegister,                                                       
				`JumpAndLinkRegister,                                                
				`Load,
				`Store:
					stall = (WR_ex == SR1_id);
			endcase
		`R_format,
		`Immediate:
			case (instr_type_id)                                                                                                               
				`BranchIfEqual,                                                      
				`BranchIfNotEqual:                                                   
					stall = 1'b1;                                                                                                              
				`JumpRegister,                                                       
				`JumpAndLinkRegister:                                                
					stall = (WR_ex == SR1_id);
			endcase
		endcase
			
		else if (regwrt_mem && (WR_mem == SR1_id || WR_mem == SR2_id) && WR_mem != 5'b0)
		case (instr_type_mem)
		`Load:	
			case (instr_type_id)
				//`R_format,
				`BranchIfEqual,
				`BranchIfNotEqual:
					stall = 1'b1;
				//`Immediate,
				`JumpRegister,
				`JumpAndLinkRegister:
				//`Load,
				//`Store:
					stall = (WR_mem == SR1_id);
			endcase
		endcase
	end
	
	always @(*)
	begin
		flush = 1'b0;
		case (instr_type_id)
			`Jump,
			`JumpRegister,
			`JumpAndLinkRegister,
			`Link:
				flush = 1'b1;
			`BranchIfEqual:
				flush = equal;
			`BranchIfNotEqual:
				flush = !equal;
		endcase
	end
				
	always @(*)
	begin
		PCsrc = 4'b0;
		case (instr_type_id)
			`Jump,
			`Link:
				PCsrc = 4'd1;
			`JumpRegister,
			`JumpAndLinkRegister:
			begin
				PCsrc = 3'd2;
				if (regwrt_ex && WR_ex == SR1_id && WR_ex != 5'b0)
					case (instr_type_ex)
						`LUI:
							PCsrc = 3'd4;
						`Link,
						`JumpAndLinkRegister:
							PCsrc = 3'd5;
					endcase
				else if (regwrt_mem && WR_mem == SR1_id && WR_mem != 5'b0)
					case (instr_type_mem)                              
							`R_format,                    
							`Immediate: PCsrc = 3'd6;                    
							`LUI: PCsrc = 3'd7;                          
							`Link,                         
							`JumpAndLinkRegister: PCsrc = 3'd8; 	        
						endcase     
				else if (regwrt_wb && WR_wb == SR1_id && WR_wb != 5'b0)
					PCsrc = 3'd9; 
					/*case (instr_type_wb)                             
							`R_format,                   
							`Immediate,                   
							`LUI,                          
							`Link,                          
							`JumpAndLinkRegister: 	        
						endcase*/  
			end
			`BranchIfEqual:
				PCsrc = equal? 4'd3 : 4'b0;
			`BranchIfNotEqual:
				PCsrc = equal? 4'b0 : 4'd3;
		endcase
	end
	
	always @(*)
	begin
		branchR1src = 3'd0;
		if (instr_type_id == `BranchIfEqual || instr_type_id == `BranchIfNotEqual)
		begin
			if (regwrt_ex && WR_ex == SR1_id && WR_ex != 5'b0)
				case (instr_type_ex)
					`LUI:
						branchR1src = 3'd1;
					`Link,
					`JumpAndLinkRegister:
						branchR1src = 3'd2;
				endcase
			else if (regwrt_mem && WR_mem == SR1_id && WR_mem != 5'b0)
				case (instr_type_mem)                              
						`R_format,                    
						`Immediate: branchR1src = 3'd3;                    
						`LUI: branchR1src = 3'd4;                          
						`Link,                         
						`JumpAndLinkRegister: branchR1src = 3'd5; 	        
				endcase     
			else if (regwrt_wb && WR_wb == SR1_id && WR_wb != 5'b0)
				branchR1src = 3'd6; 
				/*case (instr_type_wb)                             
						`R_format,                   
						`Immediate,                   
						`LUI,                          
						`Link,                          
						`JumpAndLinkRegister: 	        
				endcase       */
		end
	end
	
	always @(*)
	begin
		branchR2src = 3'd0;
		if (instr_type_id == `BranchIfEqual || instr_type_id == `BranchIfNotEqual)
		begin
			if (regwrt_ex && WR_ex == SR2_id && WR_ex != 5'b0)
				case (instr_type_ex)
					`LUI:
						branchR2src = 3'd1;
					`Link,
					`JumpAndLinkRegister:
						branchR2src = 3'd2;
				endcase
			else if (regwrt_mem && WR_mem == SR2_id && WR_mem != 5'b0)
				case (instr_type_mem)                              
						`R_format,                    
						`Immediate:
							branchR2src = 3'd3;                    
						`LUI: 
							branchR2src = 3'd4;                          
						`Link,                         
						`JumpAndLinkRegister:
							branchR2src = 3'd5; 	        
					endcase     
			else if (regwrt_wb && WR_wb == SR2_id && WR_wb != 5'b0)
				branchR1src = 3'd6; 
				/*case (instr_type_wb)                             
						`R_format,                   
						`Immediate,                   
						`LUI,                          
						`Link,                          
						`JumpAndLinkRegister: 	        
				endcase       */
		end
	end
	
	always @(*)
	begin
		rd1_write_thru = 1'b0;
		if (regwrt_wb && SR1_id == WR_wb && WR_wb != 5'b0)
			rd1_write_thru = 1'b1;
	end	
	
	always @(*)
	begin
		rd2_write_thru = 1'b0;
		if (regwrt_wb && SR2_id == WR_wb && WR_wb != 5'b0)
			rd2_write_thru = 1'b1;
	end	
	
	always @(*)                                                        
	begin                                                                 
		alusrcA = 0;                                                   
		if (regwrt_mem && WR_mem == ALUsr1_ex && WR_mem != 5'b0)                         
			case (instr_type_ex)                                       
				`R_format,                                            
				`Load,                                                 
				`Store,                                                
				`Immediate:                                            
					case (instr_type_mem)                              
						`R_format,                    
						`Immediate: alusrcA = 3'd1;                    
						`LUI: alusrcA = 3'd3;                          
						`Link,                         
						`JumpAndLinkRegister: alusrcA = 3'd2; 	        
					endcase                                            	
			endcase                                                    	
		else if (regwrt_wb && WR_wb == ALUsr1_ex && WR_wb != 5'b0)
			case (instr_type_ex)                                       
				`R_format,                                             
				`Load,                                                 
				`Store,                                                
				`Immediate:                                           
					/*case (instr_type_wb)                             
						`R_format,                   
						`Immediate,                   
						`LUI,                          
						`Link,                          
						`JumpAndLinkRegister: 	        
					endcase               
					*/alusrcA = 3'd4; 					
			endcase              
	end         

	always @(*)                                                        
	begin                                                                 
		alusrcB = 3'b0;    
		if (instr_type_ex == `Immediate || instr_type_ex == `Load || instr_type_ex == `Store) 
			alusrcB = 3'b1;
		else if (regwrt_mem && WR_mem == ALUsr2_ex && WR_mem != 5'b0)                         
			case (instr_type_ex)                                       
				`R_format:                                            
				//`Load,                                                 
				//`Store:                                                
				//`Immediate:                                            
					case (instr_type_mem)                              
						`R_format,                   
						`Immediate: alusrcB = 3'd2;                    
						`LUI: alusrcB = 3'd4;                          
						`Link,                         
						`JumpAndLinkRegister: alusrcB = 3'd3; 	        
					endcase                                            	
			endcase                                                    	
		else if (regwrt_wb && WR_wb == ALUsr2_ex && WR_wb != 5'b0)
			case (instr_type_ex)                                       
				`R_format:                                            
				//`Load,                                                 
				//`Store:                                                
				//`Immediate:                                           
					/*case (instr_type_wb)                             
						`R_format,                
						`Immediate,                
						`LUI,               
						`Link,               
						`JumpAndLinkRegister:  	        
					endcase    */        
					alusrcB = 3'd5;					
			endcase              
	end                       
	
	always @(*)
	begin
	memWrtSrc = 1'b0;
	if (regwrt_wb && WR_wb == STSr_mem && instr_type_mem == `Store && WR_wb != 5'b0)
		memWrtSrc = 1'b1;												
	end
                                                                       	
endmodule                                                              	
                                                                       	
module IF_stage                                                        	
(                                                                      	
	clk,
	reset,
	flush,
	PCsrc,
	RD1_id,
	//RD1_ex,
	RD1_mem_alu,
	RD1_wb,
	branch_pc_id,
	jump_pc_id,
	instr,
	next_pc_if,
	//next_pc_id,
	next_pc_ex,
	next_pc_mem,
	//ui_id,
	ui_ex,
	ui_mem,
	PCwrt
);
	input clk, reset, PCwrt;
	input flush, PCsrc;
	input [3:0] PCsrc;
	input [31:0]
	RD1_id,
	//RD1_ex,
	RD1_mem_alu,
	RD1_wb,
	branch_pc_id,
	jump_pc_id,
	//next_pc_id,
	//ui_id,
	ui_ex,
	next_pc_ex,
	next_pc_mem,
	ui_mem;
	
	output [31:0] instr;
	
	reg [31:0] pc;
	output [31:0] next_pc_if;
	wire [31:0] mem_instr;
	
	assign next_pc_if =	pc + 32'd4;
	
	always @(posedge clk)
	begin:PC_always
		if (reset)
			pc <= 32'b0;
		else if (PCwrt)
			case(PCsrc) //synopsys parallel_case
				4'd0:    pc <= next_pc_if;//default
				4'd1:    pc <= jump_pc_id;//{next_pc[31:28], instr[25:0], 2'b0};// for j and jal
				4'd2:    pc <= RD1_id;// for jr and jalr
				4'd3:    pc <= branch_pc_id;// next_pc + (imm_32 << 2); for beq and bne
				//4'd4:    pc <= next_pc_id;
				//4'd5:    pc <= ui_id;
				4'd4:    pc <= ui_ex;
				4'd5:    pc <= next_pc_ex;
				4'd6:    pc <= RD1_mem_alu;// for jr and jalr forwarded from alu result stored in the mem stage
				4'd7:    pc <= ui_mem;
				4'd8:   pc <= next_pc_mem;
				4'd9:   pc <= RD1_wb;// for jr and jalr forwarded from wb stage
				default: pc <= 32'bx;
			endcase
	end
	
	async_mem instr_mem(
   .clk(),
   .write(1'b0),
   .address(pc),
   .write_data(),
    .read_data(mem_instr)
	);
	
	assign instr = (flush)? 32'b0_100000 : mem_instr;
	
endmodule

module IF_ID
(
	clk,
	reset,
	next_pc_if,
	next_pc_id,
	instr_if,
	instr_id,
	stall
);
	input clk, reset, stall;
	input [31:0] next_pc_if, instr_if;
	output [31:0] next_pc_id, instr_id;
	
	gp_reg #(32) next_pc(.clk(clk), .reset(reset), .D(stall?next_pc_id:next_pc_if), .Q(next_pc_id));
	gp_reg #(32) instr(.clk(clk), .reset(reset), .D(stall?instr_id:instr_if), .Q(instr_id));

endmodule

module ID_stage
(
	clk,
	instr,
	WD_wb2rf,
	regDst,
	regwrt,
	WR_id,
	WR_wb2rf,
	se_ze,
	branchR1src,
	branchR2src,
	RD_mem_alu,
	rd1_write_thru,
	rd2_write_thru,
	RD1,
	RD2,
	equal,
	SR1,
	SR2, 
	imm_32,
	ui_id,
	ui_ex,
	next_pc_ex,
	next_pc,
	ui_mem,
	next_pc_mem,
	branch_pc,
	RD1_id,
	jump_pc
);
	input clk, se_ze, regwrt, rd1_write_thru, rd2_write_thru;
	input [2:0] branchR1src, branchR2src;
	input [1:0]	regDst;
	input [31:0] 
	next_pc,
	instr, 
	RD_mem_alu, 
	WD_wb2rf,
	ui_ex,
	next_pc_ex,
	ui_mem,
	next_pc_mem;
	
	input [4:0] WR_wb2rf;//, RD_wb;//write_data from write back into the register file, write_regsiter from wb
	
	output [31:0] imm_32, RD1_id, branch_pc, ui_id, jump_pc;
	output reg [4:0] WR_id;
	output [4:0] SR1, SR2;//, STSr;
	output reg [31:0] RD1, RD2;
	output equal;
	
	wire [31:0] rf_RD1, rf_RD2;
	reg [31:0] branch_RD1, branch_RD2;
	
	assign RD1_id = rf_RD1;
	assign imm_32 = se_ze ? {{16{instr[15]}},instr[15:0]}: {16'b0, instr[15:0]};
	
	assign equal = (branch_RD1 == branch_RD2);
	assign branch_pc = next_pc + {{14{instr[15]}}, instr[15:0], 2'b0};
	assign jump_pc = {next_pc[31:28], instr[25:0], 2'b0};
	assign SR1 = instr[25:21];
	assign SR2 = instr[20:16];
	//assign STSr = instr[20:16];
	assign ui_id = {instr[15:0], 16'b0};
	
	always @(*)
	begin
		case (branchR1src)
		3'd0:
			branch_RD1 = rf_RD1;
		3'd1:
			branch_RD1 = ui_ex;
		3'd2:
			branch_RD1 = next_pc_ex;
		3'd3:
			branch_RD1 = RD_mem_alu;
		3'd4:
			branch_RD1 = ui_mem;
		3'd5:
			branch_RD1 = next_pc_mem;
		3'd6:
			branch_RD1 = WD_wb2rf;
		default:
			branch_RD1 = 32'bx;
		endcase
	end
	
	always @(*)
	begin
		case (branchR2src)
		3'd0:
			branch_RD2 = rf_RD2;
		3'd1:
			branch_RD2 = ui_ex;
		3'd2:
			branch_RD2 = next_pc_ex;
		3'd3:
			branch_RD2 = RD_mem_alu;
		3'd4:
			branch_RD2 = ui_mem;
		3'd5:
			branch_RD2 = next_pc_mem;
		3'd6:
			branch_RD2 = WD_wb2rf;
		default:
			branch_RD2 = 32'bx;
		endcase
	end
	
	always @(*)
	begin
		case(rd1_write_thru)
		1'b0:
			RD1 = rf_RD1;
		1'b1:
			RD1 = WD_wb2rf;
		endcase
	end
	
	always @(*)
	begin
		case(rd2_write_thru)
		1'b0:
			RD2 = rf_RD2;
		1'b1:
			RD2 = WD_wb2rf;
		endcase
	end
	
	always @(*)//goes forward in the pipline and not to the register file
	begin
		case (regDst)
		2'b00:
			WR_id = instr[20:16];//instr[15:11];
		2'b01:
			WR_id = instr[15:11];//instr[20:16];
		2'b10:
			WR_id = 5'd31;
		default:
			WR_id = 5'bx;
		endcase
	end
	
	reg_file rf(
   .clk(clk),
   .write(regwrt),
   .WR(WR_wb2rf),
   .WD(WD_wb2rf),
   .RR1(instr[25:21]),
   .RR2(instr[20:16]),
   .RD1(rf_RD1),
   .RD2(rf_RD2)
	);
endmodule

module ID_EX
(
	clk,
	reset,
	aluR1_id,
	aluR2_id,
	aluR1_ex,
	aluR2_ex,
	imm_32_id,
	imm_32_ex,
	WR_id,
	WR_ex,
	RD1_thru_id,
	RD2_thru_id,
	RD1_ex,
	RD2_ex,
	next_pc_id,
	next_pc_ex,
	ui_id,
	ui_ex,
	aluOp_id,
	aluOp_ex,
	instr_type_id,
	instr_type_ex,
	regwrt_id,
	regwrt_ex,
	memwrt_id,
	memwrt_ex,
	regDataSel_id,
	regDataSel_ex
);
	input clk, reset, regwrt_id, memwrt_id;
	input [1:0] regDataSel_id;
	input [4:0] aluR1_id, aluR2_id, WR_id;
	input [3:0] aluOp_id, instr_type_id;
	output [1:0] regDataSel_ex;
	output [3:0] aluOp_ex, instr_type_ex;
	input [31:0] RD1_thru_id, RD2_thru_id, next_pc_id, ui_id, imm_32_id;
	output [4:0] aluR1_ex, aluR2_ex, WR_ex;
	output [31:0] RD1_ex, RD2_ex, next_pc_ex, ui_ex, imm_32_ex;
	output regwrt_ex, memwrt_ex;
	
	gp_reg #(1) regwrt(.clk(clk), .reset(reset), .D(regwrt_id), .Q(regwrt_ex));
	gp_reg #(1) memwrt(.clk(clk), .reset(reset), .D(memwrt_id), .Q(memwrt_ex));
	gp_reg #(2) regDataSel(.clk(clk), .reset(reset), .D(regDataSel_id), .Q(regDataSel_ex));
	gp_reg #(4) instr_type(.clk(clk), .reset(reset), .D(instr_type_id), .Q(instr_type_ex));
	gp_reg #(4) aluOp(.clk(clk), .reset(reset), .D(aluOp_id), .Q(aluOp_ex));//aluop register
	gp_reg #(5) aluR1(.clk(clk), .reset(reset), .D(aluR1_id), .Q(aluR1_ex));//op1 register
	gp_reg #(5) aluR2(.clk(clk), .reset(reset), .D(aluR2_id), .Q(aluR2_ex));//op2 register
	//gp_reg #(5) STR(.clk(clk), .reset(reset), .D(STR_id), .Q(STR_ex));//store register
	gp_reg #(5) WR(.clk(clk), .reset(reset), .D(WR_id), .Q(WR_ex));//Write back register register
	gp_reg #(32) RD1(.clk(clk), .reset(reset), .D(RD1_thru_id), .Q(RD1_ex));
	gp_reg #(32) RD2(.clk(clk), .reset(reset), .D(RD2_thru_id), .Q(RD2_ex));
	gp_reg #(32) next_pc(.clk(clk), .reset(reset), .D(next_pc_id), .Q(next_pc_ex));//next pc
	gp_reg #(32) ui(.clk(clk), .reset(reset), .D(ui_id), .Q(ui_ex));//upper immediate
	gp_reg #(32) imm_32(.clk(clk), .reset(reset), .D(imm_32_id), .Q(imm_32_ex));//32-bit immediate
	
endmodule

module EX_stage
(
	RD1,
	RD_mem_alu,
	RD_mem_next_pc,
	RD_mem_ui,
	RD_wb,
	RD2,
	alusrcA,
	alusrcB,
	imm_32,
	aluOp,
	alu_result
);
	input [3:0] aluOp;
	input [31:0] imm_32, RD1, RD_mem_alu, RD_wb, RD2, RD_mem_next_pc, RD_mem_ui;
	input [2:0] alusrcA, alusrcB;
	
	output [31:0] alu_result; 
	
	reg [31:0] aluA, aluB;
	
	always @(*)
	begin
		aluA = 32'bX;
		case(alusrcA)
		3'b000: aluA = RD1;
		3'b001: aluA = RD_mem_alu;
		3'b010: aluA = RD_mem_next_pc;
		3'b011: aluA = RD_mem_ui;
		3'b100: aluA = RD_wb;
		endcase
	end
	always @(*)
	begin
		aluB = 32'bX;
		case(alusrcB)
		3'b000: aluB = RD2;
		3'b001: aluB = imm_32;
		3'b010: aluB = RD_mem_alu;
		3'b011: aluB = RD_mem_next_pc;
		3'b100: aluB = RD_mem_ui;
		3'b101: aluB = RD_wb;
		3'b110: aluB = (imm_32 << 2);
		endcase
	end
	
	my_alu alu(
   .aluA(aluA),
   .aluB(aluB),
   .aluOp(aluOp),
   .aluResult(alu_result),
   .aluZero()
);
endmodule

module EX_MEM
(
	clk,
	reset,
	alu_result_ex,
	alu_result_mem,
	STR_ex,
	STR_mem,
	next_pc_ex,
	next_pc_mem,
	ui_ex,
	ui_mem,
	RD2_ex,
	RD2_mem,
	memwrt_ex,
	memwrt_mem,
	WR_ex,
	WR_mem,
	regwrt_ex,
	regwrt_mem,
	instr_type_ex,
	instr_type_mem,
	regDataSel_ex,
	regDataSel_mem
);
	input clk, reset, memwrt_ex, regwrt_ex;
	input [1:0] regDataSel_ex;
	output [1:0] regDataSel_mem;
	input [31:0] alu_result_ex, next_pc_ex, ui_ex, RD2_ex;
	output [31:0] alu_result_mem, next_pc_mem, ui_mem, RD2_mem;
	output memwrt_mem, regwrt_mem;
	input [3:0] instr_type_ex;
	output [3:0] instr_type_mem;
	input [4:0] STR_ex, WR_ex;
	output [4:0] STR_mem, WR_mem;
	
	gp_reg #(1) regwrt(.clk(clk), .reset(reset), .D(regwrt_ex), .Q(regwrt_mem));
	gp_reg #(1) memwrt(.clk(clk), .reset(reset), .D(memwrt_ex), .Q(memwrt_mem));
	gp_reg #(2) regDataSel(.clk(clk), .reset(reset), .D(regDataSel_ex), .Q(regDataSel_mem));
	gp_reg #(4) instr_type(.clk(clk), .reset(reset), .D(instr_type_ex), .Q(instr_type_mem));
	gp_reg #(5) STR(.clk(clk), .reset(reset), .D(STR_ex), .Q(STR_mem));
	gp_reg #(5) WR(.clk(clk), .reset(reset), .D(WR_ex), .Q(WR_mem));
	gp_reg #(32) RD2(.clk(clk), .reset(reset), .D(RD2_ex), .Q(RD2_mem));
	gp_reg #(32) alu_result(.clk(clk), .reset(reset), .D(alu_result_ex), .Q(alu_result_mem));
	gp_reg #(32) next_pc(.clk(clk), .reset(reset), .D(next_pc_ex), .Q(next_pc_mem));
	gp_reg #(32) ui(.clk(clk), .reset(reset), .D(ui_ex), .Q(ui_mem));
endmodule

module MEM_stage
(
	clk,
	memwrt,
	memWrtSrc,
	RD2,
	alu_result,
	//RDf_mem_alu,
	memRD,
	RD2_wb
);
input memwrt, memWrtSrc, clk;
input [31:0] RD2, alu_result, RD2_wb;

//output [31:0] RDf_mem_alu;
output [31:0] memRD;

reg[31:0] mem_write_data;

//assign RDf_mem_alu = alu_result;

async_mem data_mem(
	.clk(clk),
	.write(memwrt),
	.address(alu_result),
	.write_data(mem_write_data),
	.read_data(memRD)
	);
	
	always @(*)
	begin
		case (memWrtSrc)
		1'b0:
			mem_write_data = RD2;
		1'b1:
			mem_write_data = RD2_wb;
		endcase
	end
endmodule

module MEM_WB
(
	clk,
	reset,
	alu_result_wb,
	alu_result_mem,
	memRD_mem,
	memRD_wb,
	next_pc_wb,
	next_pc_mem,
	regDataSel_mem,
	regDataSel_wb,
	ui_mem,
	ui_wb,
	WR_mem,
	WR_wb,
	regwrt_mem,
	regwrt_wb
);

	input clk, reset, regwrt_mem;
	input [1:0] regDataSel_mem;
	input [1:0] regDataSel_wb;
	input [4:0] WR_mem, WR_wb;
	input [31:0] alu_result_mem, next_pc_mem, memRD_mem, ui_mem;
	output [31:0] alu_result_wb, next_pc_wb, memRD_wb, ui_wb;
	output regwrt_wb;
	
	gp_reg #(1) regwrt(.clk(clk), .reset(reset), .D(regwrt_mem), .Q(regwrt_wb));
	gp_reg #(2) regDataSel(.clk(clk), .reset(reset), .D(regDataSel_mem), .Q(regDataSel_wb));
	gp_reg #(5) WR(.clk(clk), .reset(reset), .D(WR_mem), .Q(WR_wb));
	gp_reg #(32) alu_result(.clk(clk), .reset(reset), .D(alu_result_mem), .Q(alu_result_wb));
	gp_reg #(32) next_pc(.clk(clk), .reset(reset), .D(next_pc_mem), .Q(next_pc_wb));
	gp_reg #(32) memRD(.clk(clk), .reset(reset), .D(memRD_mem), .Q(memRD_wb));
	gp_reg #(32) ui(.clk(clk), .reset(reset), .D(ui_mem), .Q(ui_wb));
endmodule

module WB_stage(
	next_pc,
	alu_result,
	ui,
	regDataSel,
	memRD,
	WD
);

	input[1:0] regDataSel;
	input [31:0] ui, next_pc, alu_result, memRD;
	
	output reg[31:0] WD;
	//output [31:0] RDf = WD;
	
	always @(*)
	begin
		case (regDataSel)
		2'b00:
			WD = next_pc;//link
		2'b01:
			WD = alu_result;//most instructions
		2'b11:
			WD = ui;//lui
		2'b10:
			WD = memRD;	//Load		
		default:
			WD = 32'bx;
		endcase
	end
endmodule

module sc_ctrl(
	clk, 
	reset,
	//zero,
	Opcode,
	funct, 
	se_ze,
	//signed_mul,
	//mult_start,
	//alusrcB,
	memwrt,
	regwrt,
	//PCsrc,
	regDst,
	regDataSel,
	aluOp,
	WBinstr_type
);
	//localparam fetch1 = 0, fetch2 = 1, fetch3 = 2, ldreg = 3, exec = 4, ls = 5, lw1 = 6, lw2 = 7, lw3 = 8, sw1 = 9, sw2 = 10,  mult_st = 11, mult_count = 12, branch_calc = 13, branch_decision = 14;
	localparam Undefined = 'bx, ArithLog = 0, ArithLogI = 1, LoadStore = 2, Branch = `Branch, Jump = `Jump, LUI = `LUI;
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
	xor_op = 6'b100110 ,
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
	
	input clk, reset;//, zero;
	input [5:0] Opcode;
	input [5:0] funct;
	
	output reg se_ze, memwrt, regwrt; //signed_mul, mult_start, alusrcB,;
	output reg [1:0] /*PCsrc,*/ regDst;
	output reg [1:0] regDataSel;
	output reg [3:0] aluOp;
	
	reg [3:0] instr_type;
	output reg [3:0] WBinstr_type;
	
	localparam  R_format = `R_format, Load = `Load,  Link = `Link, Immediate = `Immediate, Store = `Store, JumpRegister = `JumpRegister, JumpAndLinkRegister = `JumpAndLinkRegister, BranchIfEqual = `BranchIfEqual, BranchIfNotEqual = `BranchIfNotEqual ;//Branch = 3 and LUI = 5 are defined above
	
	always @(*)
	begin
		WBinstr_type = 4'bX;
		case (Opcode)
			6'b0:                                                              
			case (funct)                                                       
				jr :                                                           
					WBinstr_type = JumpRegister;                               
				jalr:                                                          
					WBinstr_type = JumpAndLinkRegister;                        
				add,                                                           
					                                                           
				sub,                                                           
					                                                           
				addu,                                                          
					                                                           
				subu,                                                          
					                                                           
				and_op,                                                        
					                                                           
				or_op,                                                         
					                                                           
				xor_op,                                                        
					                                                           
				nor_op,                                                        
					                                                           
				slt,                                                           
				sltu:                                                          
					WBinstr_type = R_format;                                   
			endcase                                                            
			addiu,                                                             
				                                                               
			slti,                                                              
				                                                               
			sltiu,                                                  
			
			andi,
			
			ori, 
			
			xori,
	
			addi:
				WBinstr_type = Immediate;
			beq  :
				WBinstr_type = BranchIfEqual;
			bne  :
				WBinstr_type = BranchIfNotEqual;
			j  :
				WBinstr_type = Jump;
			jal  :
				WBinstr_type = Link;
			lui:
				WBinstr_type = LUI;
			lw:
				WBinstr_type = Load;
			sw:
				WBinstr_type = Store;
		endcase
	end
	
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
			/*	mfhi:
					instr_type = Move;
				mflo :
					instr_type = Move;
				mult:
					instr_type = Multiply;
				multu:
					instr_type = Multiply;*/
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
		se_ze = 1'bx; /*signed_mul = 1'bx; mult_start = 1'b0;*/ memwrt = 1'b0; regwrt = 1'b0;   
		/*PCsrc = 2'bx; alusrcB = 1'bx;*/ regDst = 2'bx;
		regDataSel = 2'bx;
		aluOp = 4'bx;
		case (instr_type)
		ArithLog:
		begin
			//PCsrc = 1'b0;
			regDataSel = 2'b01;
			regDst = 2'b01;
			regwrt = 1'b1;
			//alusrcB = 0;
			
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
			//PCsrc = 1'b0;
			regDataSel = 2'b01;
			regDst = 2'b0;
			regwrt = 1'b1;
			//alusrcB = 1;
			
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
			//PCsrc = 0;
			aluOp = `ADD;
			//alusrcB = 1;
			se_ze = 1;
			case (Opcode)
			lw:
			begin
				regwrt = 1'b1;
				regDataSel = 2'b10;
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
			//PCsrc = (Opcode == beq && zero) || (Opcode == bne && !zero)?2'b11:2'b0;
			aluOp = `SUB;
			//alusrcB = 0;
			se_ze = 1;
		end
		Jump:
		begin
			case (Opcode)
				6'b0:
				begin
					//PCsrc = 2'b10;
					case (funct)
					//jr:
					jalr:
					begin
						regwrt = 1'b1;
						regDst = 2'b10;
						regDataSel = 2'b0;
					end
					endcase
				end
				//j:
					//PCsrc = 2'b1;
				jal:
				begin
					//PCsrc = 2'b1;
					regwrt = 1'b1;
					regDst = 2'b10;
					regDataSel = 2'b0;
				end
			endcase
		end
		/*Multiply:
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
		end*/
		LUI:
		begin
			//PCsrc = 1'b0;
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
        `ADD  :  aluResult =  aluA + aluB;           // add
        `SUB  :  aluResult =  aluA + ~aluB + 1'b1;      // sub
        `AND  :  aluResult =  aluA & aluB;
        `OR   :  aluResult =  aluA | aluB;
        `NOR  :  aluResult =   ~( aluA | aluB );//aluA ~| aluB;    // ?? ~ ( aluA | aluB )
        `XOR  :  aluResult =  aluA ^ aluB;
        `SLT  :  aluResult =  $signed(aluA) < $signed(aluB)? 32'b1:32'b0;
		`SLTU :  aluResult =  $unsigned(aluA) < $unsigned(aluB)? 32'b1:32'b0;
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

   assign read_data = mem_data[ address[31:2] ];

   always @(posedge clk)
      if(write)
         mem_data[ address[31:2] ] <= write_data;

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

   assign RD1 = rf_data[ RR1 ];

   assign RD2 = rf_data[ RR2 ];

   always @(posedge clk) begin
      if(write) begin
         rf_data[ WR ] <= WD;

         `ifdef DEBUG
         if(WR)
            $display("$%0d = %x", WR, WD);
         `endif

      end
      rf_data[0] <= 32'h00000000;
   end

endmodule

module gp_reg (clk, reset, D, Q);
	parameter size = 1;
	input clk, reset;
	input [size - 1:0] D;
	output reg [size - 1:0] Q;
	
	always @(posedge clk)
	begin
		if (reset)
			Q <= {size{1'b0}};
		else
			Q <= D;
	end
endmodule