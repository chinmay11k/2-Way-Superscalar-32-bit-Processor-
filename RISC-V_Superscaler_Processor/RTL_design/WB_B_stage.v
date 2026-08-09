module WB_B(
input clk,
input reset,
input [31:0] MEM_WB_IR_B,
input [31:0] MEM_WB_ALUout_B,
input [31:0] MEM_WB_LMD_B,
input [2:0]  MEM_WB_TYPE_B,
input        MEM_WB_AGE_B,

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
// OPCODES
//===========================================

parameter
    LOAD = 7'b0000011;

wire [6:0] opcode;

assign opcode = MEM_WB_IR_B[6:0];

//===========================================
// WB LOGIC
//===========================================

always @(posedge clk)
begin
    if(reset) begin
        write_en   <=0; 
        rd         <=0; 
        write_data <=0; 
        age        <=1'b0;
    end else begin
        age <= MEM_WB_AGE_B;
        case(MEM_WB_TYPE_B)

TYPE_R:
begin
    write_en   <= 1'b1;
    rd         <= MEM_WB_IR_B[11:7];
    write_data <= MEM_WB_ALUout_B;
end

TYPE_I,TYPE_U:
begin

    rd <= MEM_WB_IR_B[11:7];

    if(opcode == LOAD)
    begin
        write_en   <= 1'b1;
        write_data <= MEM_WB_LMD_B;
    end

    else
    begin
        write_en   <= 1'b1;
        write_data <= MEM_WB_ALUout_B;
    end

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