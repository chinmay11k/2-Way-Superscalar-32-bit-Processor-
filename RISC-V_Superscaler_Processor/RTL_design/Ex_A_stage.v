module EX_A_STAGE(

input clk,
input reset,
input stall_EX,

input  [31:0] ID_EX_IR_A,
input  [31:0] ID_EX_PC_A,
input  [31:0] ID_EX_X0_A,
input  [31:0] ID_EX_X1_A,
input  [31:0] ID_EX_IMM_A,
input  [2:0]  ID_EX_TYPE_A,
input         ID_EX_AGE_A,

output reg [31:0] EX_MEM_IR_A,
output reg [31:0] EX_MEM_ALUout_A,
output reg [2:0]  EX_MEM_TYPE_A,
output reg        EX_MEM_AGE_A,

output reg branched,
output reg [31:0] next_pc,
output wire branch_taken

);

wire [31:0] alu_out;
wire [31:0] branch_pc;

ALU_A aluA(
    .A(ID_EX_X0_A),
    .B(ID_EX_X1_A),
    .IMM(ID_EX_IMM_A),
    .PC(ID_EX_PC_A),
    .IR(ID_EX_IR_A),
    .ALUout(alu_out),
    .branch_taken(branch_taken),
    .next_pc(branch_pc)
);

always @(posedge clk)
begin

if(reset)
begin
    EX_MEM_IR_A     <= 32'd0;
    EX_MEM_ALUout_A <= 32'd0;
    EX_MEM_TYPE_A   <= 3'b111;
    EX_MEM_AGE_A    <= 1'b0;

    branched        <= 1'b0;
    next_pc         <= 32'd0;
end

else //if(stall_EX == 0)
begin

    EX_MEM_IR_A     <= ID_EX_IR_A;
    EX_MEM_ALUout_A <= alu_out;
    EX_MEM_TYPE_A   <= ID_EX_TYPE_A;
    EX_MEM_AGE_A    <= ID_EX_AGE_A;

    branched        <= branch_taken;
    next_pc         <= branch_pc;

end

end

endmodule