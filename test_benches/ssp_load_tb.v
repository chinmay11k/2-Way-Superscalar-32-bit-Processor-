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


module SSP_load_tb;
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
 R15 = 5'b01111;           
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
   ssp.REG[i]<=16'd0;
end
for(j=0;j<1028;j=j+1)
begin
   ssp.MEM[j]<={NOP,26'd0};  
end
 #1;
  ssp.MEM[1]<={LW,R0,R1,16'd50};
  ssp.MEM[4]<={LW,R0,R2,16'd40};
  ssp.MEM[2]<={LW,R0,R3,16'd80};
  ssp.MEM[50]<=32'd100;
  ssp.MEM[40]<=32'd100;
  ssp.MEM[80]<=32'd100;
  
end

//reser test
initial
begin
reset=1;
#30 reset =0;
#200 $finish;
end
endmodule
