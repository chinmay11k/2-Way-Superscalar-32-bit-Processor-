`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.01.2026 18:33:11
// Design Name: 
// Module Name: SSP_load_store_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SSP_opcode_I_tb;
reg clk1,clk2;
reg reset;
integer i,j;  

superscaler_processor ssp(.clk1(clk1),
                          .clk2(clk2),
                          .reset(reset));
               
 //paramerizing REGISTER number and opcode
 //for easy MEM initialization
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
     JAL  = 6'b100001,
     
     //no oparations 
     NOP  = 6'b111111;
 parameter
R0  = 5'b00000,
 R1  = 5'b00001,
 R2  = 5'b00010,
 R3  = 5'b00011,
 R4  = 5'b00100,
 R5  = 5'b00101,
 R6  = 5'b00110,
 R7  = 5'b00111,
 R8  = 5'b01000,
 R9  = 5'b01001,
 R10 = 5'b01010,
 R11 = 5'b01011,
 R12 = 5'b01100,
 R13 = 5'b01101,
 R14 = 5'b01110,
 R15 = 5'b01111,
 R16 = 5'b10000,
 R17 = 5'b10001,
 R18 = 5'b10010,
 R19 = 5'b10011,
 R20 = 5'b10100,
 R21 = 5'b10101,
 R22 = 5'b10110,
 R23 = 5'b10111,
 R24 = 5'b11000,
 R25 = 5'b11001,
 R26 = 5'b11010,
 R27 = 5'b11011,
 R28 = 5'b11100,
 R29 = 5'b11101,
 R30 = 5'b11110,
 R31 = 5'b11111;
 
//clk generation
initial 
begin
clk1=0;clk2=0;
forever begin
       #5 clk1=1;
       #5 clk1=0;
       #5 clk2=1;
       #5 clk2=0; 
end
end

//register file initiation with 0
//mem file with nop 00
initial 
begin
for(i=0;i<32;i=i+1)
begin
   ssp.REG[i]<=i;
end
for(j=0;j<1028;j=j+1)
begin
   ssp.MEM[j]<={NOP,26'd0};  
end
 #1;
 //opcode writing style for I type 
// {opecode,rs1,rd,16 bits IMM data  } rs=reg ,rd =destination reg  
 
ssp.MEM[0] <= {ADD, R10, R1,  R20, 11'd0}; // 10 + 1 = 11
ssp.MEM[1] <= {SUB, R3,  R2,  R21, 11'd0}; // 3 - 2 = 1
ssp.MEM[2] <= {MUL, R4,  R5,  R22, 11'd0}; // 4 x 5 = 20
ssp.MEM[3] <= {AND, R6,  R7,  R23, 11'd0}; // 110 & 111 = 110 (6)
ssp.MEM[4] <= {OR,  R8,  R9,  R24, 11'd0}; // 1000 | 1001 = 1001 (9)
ssp.MEM[5] <= {XOR, R10, R11, R25, 11'd0}; // 1010 ^ 1011 = 0001 (1)
ssp.MEM[6] <= {SLL, R13, R1,  R26, 11'd1}; // 13 << 1 = 26
ssp.MEM[7] <= {SRL, R12, R2,  R27, 11'd2}; // 12 >> 2 = 3
// ADDI: rd = rs1 + imm
ssp.MEM[8] <= {ADDI, R5,  R28, 16'd7};    // 5 + 7 = 12

// SUBI: rd = rs1 - imm (negative result)
ssp.MEM[9] <= {SUBI, R4,  R29, 16'd9};    // 4 - 9 = -5

// ANDI: masking lower bits
ssp.MEM[10] <= {ANDI, R15, R30, 16'd3};    // 1111 & 0011 = 0011 (3)

// ORI: force bits high
ssp.MEM[11] <= {ORI,  R2,  R31, 16'd12};   // 0010 | 1100 = 1110 (14)

// XORI: toggle bits
ssp.MEM[12] <= {XORI, R9,  R19, 16'd15};   // 1001 ^ 1111 = 0110 (6)

end

//reser test
initial
begin
reset=1;
#30 reset =0;
#400 $finish;
end
endmodule
