module EX_B_STAGE(

input clk,
input reset,
input stall_EX,
input branched,

input  [31:0] ID_EX_IR_B,
input  [31:0] ID_EX_X0_B,
input  [31:0] ID_EX_X1_B,
input  [31:0] ID_EX_IMM_B,
input  [31:0] ID_EX_PC_B,
input  [2:0]  ID_EX_TYPE_B,
input         ID_EX_AGE_B,

output reg [31:0] EX_MEM_IR_B,
output reg [31:0] EX_MEM_ALUout_B,
output reg [31:0] EX_MEM_X1_B,
output reg [2:0]  EX_MEM_TYPE_B,
output reg        EX_MEM_AGE_B
);

parameter NOP_INST = 32'h00000013;
parameter TYPE_NOP = 3'b111;

wire [31:0] alu_out;

ALU_B aluB(
    .A(ID_EX_X0_B),
    .B(ID_EX_X1_B),
    .PC(ID_EX_PC_B),
    .IMM(ID_EX_IMM_B),
    .IR(ID_EX_IR_B),
    .ALUout(alu_out)
);

always @(posedge clk)
begin

    if(reset)
    begin
        EX_MEM_IR_B     <= 32'd0;
        EX_MEM_ALUout_B <= 32'd0;
        EX_MEM_X1_B     <= 32'd0;
        EX_MEM_TYPE_B   <= TYPE_NOP;
        EX_MEM_AGE_B    <= 1'b0;
    end

    else //if(stall_EX == 0)
    begin

        // Branch taken and B instruction is younger
        if(branched && ID_EX_AGE_B)
        begin
            EX_MEM_IR_B     <= NOP_INST;
            EX_MEM_ALUout_B <= 32'd0;
            EX_MEM_X1_B     <= 32'd0;
            EX_MEM_TYPE_B   <= TYPE_NOP;
            EX_MEM_AGE_B    <= 1'b0;
        end

        // Older instruction or no branch
        else
        begin
            EX_MEM_IR_B     <= ID_EX_IR_B;
            EX_MEM_ALUout_B <= alu_out;
            EX_MEM_X1_B     <= ID_EX_X1_B;
            EX_MEM_TYPE_B   <= ID_EX_TYPE_B;
            EX_MEM_AGE_B    <= ID_EX_AGE_B;
        end

    end

end

endmodule