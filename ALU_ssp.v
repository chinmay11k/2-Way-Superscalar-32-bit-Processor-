`timescale 1ns / 1ps
module ALU(
input[31:0]A,B,PC,IR,
input signed [31:0] IMM,
input [2:0]type,
output reg [31:0]ALUout );
//op-coad parameters
parameter 
// R type 
    ADD  = 6'b000000,
    SUB  = 6'b000001,
    MUL  = 6'b000010,
    AND  = 6'b000011,
    OR   = 6'b000100,
    XOR  = 6'b000101,
    SLL  = 6'b000110,
    SRL  = 6'b000111,
    //I type
    ADDI = 6'b001000,
    SUBI = 6'b001001,
    ANDI = 6'b001010,
    ORI  = 6'b001011,
    XORI = 6'b001100,
    // mem type 
    LW   = 6'b010000,
    SW   = 6'b010001,
    //branch type 
    BEQ  = 6'b011000,
    BNE  = 6'b011001,
    BLT  = 6'b011010,
    BGE  = 6'b011011,
    //jump type 
    J    = 6'b100000,
    
    //no oparations 
    NOP  = 6'b111111;

// PARAMETER FOR TYPE OF INSTRUCTION
parameter
//types 
RR_ALU=3'b000, 
RI_ALU=3'b001,
LOAD=3'b010,
STORE=3'b011,
BRANCH=3'b100,
JUMP=3'B101,
Nop=3'b111;


always@(*)
begin
case(type)
   RR_ALU:begin
           case(IR[31:26])
               ADD:ALUout<=  A+B;
               SUB:ALUout<=  A-B;
               AND:ALUout<=  A&B;
               OR:ALUout<=  A|B;
               SRL:ALUout<=  A>>B;
               SLL:ALUout<=  A<<B;
               MUL:ALUout<=  A*B;
               XOR:ALUout<=  A^B;
        
               default :ALUout<= 32'hxxxxxxxx;
            endcase
            end
   RI_ALU:begin
        case(IR[31:26])
        ADDI:ALUout<=  A+IMM;
        SUBI:ALUout<=  A-IMM;
        ANDI:ALUout<=  A&IMM;
        ORI:ALUout<=  A|IMM;
        XORI:ALUout<=  A^IMM;
        
        default :ALUout<= 32'hxxxxxxxx;
        endcase
        end
     
   LOAD,STORE:
      begin
      ALUout<=  A+IMM;
      end
    
   BRANCH:
   ALUout<=  PC+IMM;
   
   JUMP:   ALUout<=PC
   +IR[25:0];     //jump to absolute adress
   default: ALUout<=0;
endcase
end
endmodule
