module WB_A(
input clk,
input reset,

input [31:0] MEM_WB_IR_A,
input [31:0] MEM_WB_ALUout_A,
input [2:0]  MEM_WB_TYPE_A,
input        MEM_WB_AGE_A,

output reg write_en,
output reg [4:0] rd,
output reg [31:0] write_data,
output reg        age
);

//===========================================
// TYPES
//===========================================

parameter
    TYPE_R   = 3'b000,
    TYPE_I   = 3'b001,
    TYPE_S   = 3'b010,
    TYPE_B   = 3'b011,
    TYPE_U   = 3'b100,
    TYPE_J   = 3'b101,
    TYPE_NOP = 3'b111;

//===========================================
// WB LOGIC
//===========================================

always @(posedge clk)
begin
if(reset)begin
    write_en   <=0; 
    rd         <=0; 
    write_data <=0; 
    age        <=1'b0;
end else
begin
    age <= MEM_WB_AGE_A;
case(MEM_WB_TYPE_A)

TYPE_R:
begin
    write_en   <= 1'b1;
    rd         <= MEM_WB_IR_A[11:7];
    write_data <= MEM_WB_ALUout_A;
end

TYPE_I:
begin
    write_en   <= 1'b1;
    rd         <= MEM_WB_IR_A[11:7];
    write_data <= MEM_WB_ALUout_A;
end

TYPE_U:
begin
    write_en   <= 1'b1;
    rd         <= MEM_WB_IR_A[11:7];
    write_data <= MEM_WB_ALUout_A;
end

TYPE_J:
begin
    write_en   <= 1'b1;
    rd         <= MEM_WB_IR_A[11:7];
    write_data <= MEM_WB_ALUout_A;
end
default:
begin
    write_en   <=0; 
    rd         <=0;  
    write_data <=0; 

end
endcase
end
end

endmodule