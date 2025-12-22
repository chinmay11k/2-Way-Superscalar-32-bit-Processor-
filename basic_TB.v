`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT GN
// Engineer: CHINMAY KULKARNI
// 
// Create Date: 23.02.2025 18:14:16
// Design Name: RISC 32BIT PIPELINED PROCESSOR
// Module Name: risc_32bit_pipeline_tb
//////////////////////////////////////////////////////////////////////////////////

module TB_Basic(  );
reg clk1,clk2;
integer k;
//parameter
Superscaler_32_inorder risc(clk1,clk2);

initial
begin
clk1=0;clk2=0;
forever begin
#10;clk1=1;#10; clk1=0;
#10;clk2=1;#10;clk2=0;
end
end


initial
begin
//risc.EX_MEM_IR[31:26]=6'b001110;
//risc.EX_MEM_cond=0;
risc.branched=0;
risc.stall_IF=0;
risc.stall_ID=0;
risc.stall_Ex=0;
end
initial
begin
for(k=0;k<32;k=k+1)
    risc.REG[k]=k;//saving some valus in REG BANK 
    
risc.MEM[0]=32'b001000_00000_00001_0000000000001010;//ADDI R1 R0 10
risc.MEM[1]=32'b001000_00000_00010_0000000000010100;//ADDI R2 R0 20
risc.MEM[2]=32'b001000_00000_00011_0000000000011010;//ADDI R3 R0 26
risc.MEM[3]=32'b000000_00100_00111_00001_00000000000;//ADD R1 R7 R4
risc.MEM[4]=32'b000001_00010_00101_00011_00000000000;//SUB R3 R2 R5
risc.MEM[5]=32'b000010_00110_00101_00100_00000000000;//MUL R4 R5 R6
risc.PC=0;

#2000;
$finish;        
end
endmodule
