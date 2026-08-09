module MEM_A(
input clk,
input reset,

input  [31:0] EX_MEM_IR_A,
input  [31:0] EX_MEM_ALUout_A,
input  [2:0]  EX_MEM_TYPE_A,
input         EX_MEM_AGE_A,

output reg [31:0] MEM_WB_IR_A,
output reg [31:0] MEM_WB_ALUout_A,
output reg [2:0]  MEM_WB_TYPE_A,
output reg        MEM_WB_AGE_A
);

parameter
    TYPE_R   = 3'b000,
    TYPE_I   = 3'b001,
    TYPE_S   = 3'b010,
    TYPE_B   = 3'b011,
    TYPE_U   = 3'b100,
    TYPE_J   = 3'b101,
    TYPE_NOP = 3'b111;

always @(posedge clk)
begin

if(reset)
begin

    MEM_WB_IR_A      <= 32'd0;
    MEM_WB_ALUout_A  <= 32'd0;
    MEM_WB_TYPE_A    <= TYPE_NOP;
    MEM_WB_AGE_A     <= 1'b0;

end

else
begin

    MEM_WB_IR_A      <= EX_MEM_IR_A;
    MEM_WB_ALUout_A  <= EX_MEM_ALUout_A;
    MEM_WB_TYPE_A    <= EX_MEM_TYPE_A;
    MEM_WB_AGE_A     <= EX_MEM_AGE_A;

end

end

endmodule