
`timescale 1ns/100ps

`define ADD 4'b0000
`define SUB 4'b0001
`define AND 4'b0100
`define XOR 4'b0101
`define OR  4'b0110
`define NOR 4'b0111

module my_cpu(

   input clk,
   input reset,

   // Memory Port
   output     [31:0] mem_addr,
   input      [31:0] mem_read_data,
   output     [31:0] mem_write_data,
   output reg        mem_write
)

   wire alu_z;
   reg [3:0] alu_op;
   reg [1:0] aluSrcB;
   reg aluSrcA, SE_ZEn, rf_wrt;
   reg pc_wrt, ir_wrt, mdr_wrt, alu_out_wrt;


   wire [31:0] rf_rd_1, rf_rd_2, alu_result;
   reg [31:0] pc, ir, mdr, alu_out_reg, aluB;


   // CONTROLLER Starts Here

   reg [3:0] state, nxt_state;

   localparam
         FETCH1 = 4'b,
         FETCH2 = 4'b

   always @(posedge clk)
      if(reset)
         state <= #1 FETCH1;
      else
         state <= #1 nxt_state;

   wire [5:0] ir_op = ir[31:26]
   wire [5:0] funct = ir[5:0];

   always @(*) begin

      nxt_state = 'bx;
      
      alu_op  = 'bx; aluSrcB = 'bx; aluSrcA = 'bx; SE_ZEn = 'bx;
      rf_wrt = 1'b0; pc_wrt = 1'b0; ir_wrt = 1'b0;
      mdr_wrt = 1'b0; mem_write = 1'b0; alu_out_wrt = 1'b0;

      case(state)
         FETCH1: begin
            IorD = 0;
            nxt_state = FETCH2;
         end
         
         
         FECT2: begin
            ir_wrt = 1'b1;    // load IR by memory data
            aluSrcA = 1'b0;      //
            aluSrcB = 2'h1;      //
            alu_op = `ADD;    //
            pc_wrt = 1'b1;    // pc <- pc + 4
            nxt_state = EXE;
         end
         
         EXE:
//          case(ir[31:26])
            case(ir_op)
               6'b000000:              // R-format
                  case(funct[5:3])

......

                     3'b100: begin     // 6th row of 3rd table of fig. 2.25 3rd edition
                        rf_wrt = 1'b1;
                        aluSrcA = 1'b1;
                        aluSrcB = 2'b00;
                        MemToReg = 1'b0;
                        nxt_state = FETCH1;
                        case(funct)
                           3'b000: alu_op = `ADD;
                           3'b001: alu_op = `ADD;
                           3'b010: alu_op = `SUB;
                           3'b011: alu_op = `SUB;
                           3'b100: alu_op = `AND;
                           3'b101: alu_op = `OR;
                           3'b110: alu_op = `XOR;
                           3'b111: alu_op = `NOR;
                        endcase
                     end
                     
......

   end

   // CONTROLLER Ends Here

   // DATA PATH Starts Here

   always @(posedge clk)
      if(reset)
         pc <= #1 32'h00000000;
      else if(pc_wrt)
         pc <= #1 alu_result;

   always @(posedge clk) if(ir_wrt)      ir <=  #1 mem_read_data;

   always @(posedge clk) if(mdr_wrt)     mdr <= #1 mem_read_data;

   always @(posedge clk) if(alu_out_wrt) alu_out_reg <= #1 alu_result;

   assign mem_write_data = rf_rd_2;

   assign mem_addr = IorD ? alu_out_reg : pc;

   wire [31:0] aluA = aluSrcA ? rf_rd_1 : pc;

   wire [31:0] SZout = SE_ZEn ? {{16{ir[15]}}, ir[15:0]} : {16'h0000, ir[15:0]};


   always @(*)
      case (aluSrcB)
         2'b00: aluB = rf_rd_2;
         2'b01: aluB = 32'h4;
         2'b10: aluB = SZout;
         2'b11: aluB = SZout << 2;
      endcase

    my_alu alu(
      .aluA(aluA),
      .aluB(aluB),
      .aluOp(alu_op),

      .aluResult(alu_result),
      .aluZero(alu_z));

    reg_file_32x32 rf(
      .clk(clk),

      .read_reg_1(ir[25:21]),
      .read_reg_2(ir[20:16]),
      .reg_data_1(rf_rd_1),
      .reg_data_2(rf_rd_2),

      .write_reg (RegDst   ? ir[15:11] : ir[20:16]),
      .write_data(MemtoReg ? mdr : alu_result),
      .write(rf_wrt));

   // DATA PATH Ends Here



endmodule

module reg_file_32x32(
   input clk,
   input  [ 4:0] read_reg_1,
   input  [ 4:0] read_reg_2,
   output [31:0] reg_data_1,
   output [31:0] reg_data_2,
   input  [ 4:0] write_reg,
   input  [31:0] write_data,
   input         write
);

   reg [31:0] reg_data [0:31];

   assign #2 reg_data_1 = reg_data[ read_reg_1 ];
   assign #2 reg_data_2 = reg_data[ read_reg_2 ];

   always @(posedge clk) begin
      if(write == 1'b1)
         reg_data[ write_reg ] <= #1 write_data;

      reg_data[ 0 ] <= #1 32'h00000000;
   end

endmodule


module my_alu(
   input [31:0] aluA,
   input [31:0] aluB,
   input [ 3:0] aluOp,

   output [31:0] aluResult,
   output        aluZero
);

   always @(*)
      case(aluOp)
         `ADD : aluResult = #2 aluA + aluB;           // add
         `SUB : aluResult = #2 aluA + ~aluB + 1'b1;      // sub
         `AND : aluResult = #2 aluA & aluB;
         `OR  : aluResult = #2 aluA | aluB;
         `NOR : aluResult = #2 aluA ~| aluB;    // ?? ~ ( aluA | aluB )
         `XOR : aluResult = #2 aluA ^ aluB;
         . . . .
      endcase

   assign aluZero = ~ | aluResult;

endmodule
      

module memory(
   input  [31:0] mem_addr,
   output [31:0] mem_read_data,
   input  [31:0] mem_write_data,
   input         mem_write
);

   reg [31:0] mem_data [0:'hffff];

   assign #9 mem_read_data = mem_data[ mem_addr ];

   always @(negedge mem_write)
      mem_data [ mem_addr ] <= #1 mem_write_data;

endmodule
