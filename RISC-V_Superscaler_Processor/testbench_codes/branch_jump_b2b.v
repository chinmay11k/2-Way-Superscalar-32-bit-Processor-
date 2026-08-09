`timescale 1ns / 1ps

//================================================================================
// RV32I SUPERSCALER PROCESSOR TESTBENCH
// Purpose: ALU operation verification without hazards
// ISA: RISC-V 32-bit (RV32I)
// Test Type: ALU Functional Test
//================================================================================

module RV32I_SSP_TB;

//================================================================================
// CLOCK AND RESET
//================================================================================
reg clk1;
reg clk2;
reg reset;
integer i, j, k;

// Instantiate RV32_top module
RV32_top RV32_SSP(
    .clk1(clk1),
    .clk2(clk2),
    .reset(reset)
);
 // RV32I MAIN OPCODES
 parameter
     LUI      = 7'b0110111,
     AUIPC    = 7'b0010111,   
     JAL      = 7'b1101111,
     JALR     = 7'b1100111,    
     BRANCH   = 7'b1100011, 
     LOAD     = 7'b0000011,
     STORE    = 7'b0100011,
     OP_IMM   = 7'b0010011,
     OP       = 7'b0110011,
 // FUNCT3 VALUES
     // ALU
     F3_ADD_SUB  = 3'b000,
     F3_SLL      = 3'b001,
     F3_SLT      = 3'b010,
     F3_SLTU     = 3'b011,
     F3_XOR      = 3'b100,
     F3_SRL_SRA  = 3'b101,
     F3_OR       = 3'b110,
     F3_AND      = 3'b111,
     // BRANCH
     F3_BEQ      = 3'b000,
     F3_BNE      = 3'b001,
     F3_BLT      = 3'b100,
     F3_BGE      = 3'b101,
     F3_BLTU     = 3'b110,
     F3_BGEU     = 3'b111,
     // LOAD
     F3_LB       = 3'b000,
     F3_LH       = 3'b001,
     F3_LW       = 3'b010,
     F3_LBU      = 3'b100,
     F3_LHU      = 3'b101,
     // STORE
     F3_SB       = 3'b000,
     F3_SH       = 3'b001,
     F3_SW       = 3'b010,
 // FUNCT7 VALUES
    F7_ADD      = 7'b0000000,
     F7_SUB      = 7'b0100000,
     F7_SLL      = 7'b0000000,
     F7_SLT      = 7'b0000000,
     F7_SLTU     = 7'b0000000,
     F7_XOR      = 7'b0000000,
     F7_SRL      = 7'b0000000,
     F7_SRA      = 7'b0100000,
     F7_OR       = 7'b0000000,
     F7_AND      = 7'b0000000,
 // INTERNAL INSTRUCTION TYPES
     TYPE_R      = 3'b000,
     TYPE_I      = 3'b001,
     TYPE_S      = 3'b010,
     TYPE_B      = 3'b011,
     TYPE_U      = 3'b100,
     TYPE_J      = 3'b101,
     TYPE_NOP    = 3'b111,
 // FUNCTIONAL UNIT TYPES
     FU_ALU      = 2'b00,
     FU_MEM      = 2'b01,
     FU_BRANCH   = 2'b10,
     FU_NONE     = 2'b11,
 // ARCHITECTURAL NOP
     NOP    = 32'h00000013; // addi x0,x0,0
     parameter 
         x0  = 5'b00000,
         x1  = 5'b00001,
         x2  = 5'b00010,
         x3  = 5'b00011,
         x4  = 5'b00100,
         x5  = 5'b00101,
         x6  = 5'b00110,
         x7  = 5'b00111,
         x8  = 5'b01000,
         x9  = 5'b01001,
         x10 = 5'b01010,
         x11 = 5'b01011,
         x12 = 5'b01100,
         x13 = 5'b01101,
         x14 = 5'b01110,
         x15 = 5'b01111,
         x16 = 5'b10000,
         x17 = 5'b10001,
         x18 = 5'b10010,
         x19 = 5'b10011,
         x20 = 5'b10100,
         x21 = 5'b10101,
         x22 = 5'b10110,
         x23 = 5'b10111,
         x24 = 5'b11000,
         x25 = 5'b11001,
         x26 = 5'b11010,
         x27 = 5'b11011,
         x28 = 5'b11100,
         x29 = 5'b11101,
         x30 = 5'b11110,
         x31 = 5'b11111;

// CLOCK GENERATION (2 Phase Clocks for Superscaler)
parameter JAL_IMM_200 =
        {
            1'b0,           // imm[20]
            10'b0001100001, // imm[10:1]
            1'b0,           // imm[11]
            8'b00000000     // imm[19:12]
        };
initial 
begin
    clk1 = 0;
    clk2 = 0;
    forever 
begin
        #5  clk1 = 1; 
        #5  clk1 = 0;
        #5  clk2 = 1;
        #5  clk2 = 0;
    end
end
initial
begin

for(i=0;i<256;i=i+1)
    RV32_SSP.FETCH.IMEM.MEM[i] = NOP;

//--------------------------------------------------
// Registers
//--------------------------------------------------

RV32_SSP.DECODE.RF.REG[1]  = 10;
RV32_SSP.DECODE.RF.REG[2]  = 20;   // BEQ not taken

RV32_SSP.DECODE.RF.REG[3]  = 50;
RV32_SSP.DECODE.RF.REG[4]  = 50;   // BNE not taken

RV32_SSP.DECODE.RF.REG[5]  = 100;
RV32_SSP.DECODE.RF.REG[6]  = 200;  // BEQ not taken

RV32_SSP.DECODE.RF.REG[7]  = 1;
RV32_SSP.DECODE.RF.REG[8]  = 2;    // BNE taken


//--------------------------------------------------
// 4 ALU OPS
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[0] =
{12'd10,x1,F3_ADD_SUB,x10,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[1] =
{12'd20,x2,F3_ADD_SUB,x11,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[2] =
{12'd30,x3,F3_ADD_SUB,x12,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[3] =
{12'd40,x4,F3_ADD_SUB,x13,OP_IMM};


//--------------------------------------------------
// BEQ NOT TAKEN
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[4] =
{7'd4,x2,x1,F3_BEQ,5'd0,BRANCH};


//--------------------------------------------------
// BNE NOT TAKEN
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[5] =
{7'd4,x4,x3,F3_BNE,5'd0,BRANCH};


//--------------------------------------------------
// JAL TAKEN
//
// PC=24
// target = instruction 36
// PC=144
// offset = 120
//--------------------------------------------------

//RV32_SSP.FETCH.IMEM.MEM[6] =
//{20'd12,x0,JAL};
RV32_SSP.FETCH.IMEM.MEM[6] =
{
    1'b0,           // imm[20]
    10'b0000111100, // imm[10:1]
    1'b0,           // imm[11]
    8'b00000000,    // imm[19:12]
    x0,
    JAL
};

//--------------------------------------------------
// SHOULD FLUSH
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[7] =
{12'd1,x0,F3_ADD_SUB,x20,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[8] =
{12'd2,x0,F3_ADD_SUB,x21,OP_IMM};


//--------------------------------------------------
// TARGET BLOCK
// instruction index 36
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[36] =
{12'd5,x1,F3_ADD_SUB,x14,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[37] =
{12'd6,x2,F3_ADD_SUB,x15,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[38] =
{12'd7,x3,F3_ADD_SUB,x16,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[39] =
{12'd8,x4,F3_ADD_SUB,x17,OP_IMM};


//--------------------------------------------------
// BEQ NOT TAKEN
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[40] =
{7'd4,x6,x5,F3_BEQ,5'd0,BRANCH};


//--------------------------------------------------
// BNE TAKEN
//
// PC=164
// target instruction 60
// PC=240
// offset=76
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[41] =
{
    1'b0,           // imm[12]
    6'b000010,      // imm[10:5]
    x8,
    x7,
    F3_BNE,
    4'b0110,        // imm[4:1]
    1'b0,           // imm[11]
    BRANCH
};

//--------------------------------------------------
// SHOULD FLUSH
//--------------------------------------------------

RV32_SSP.FETCH.IMEM.MEM[42] =
{12'd9,x0,F3_ADD_SUB,x22,OP_IMM};

RV32_SSP.FETCH.IMEM.MEM[43] =
{12'd10,x0,F3_ADD_SUB,x23,OP_IMM};

end


// Expected:
//
// 0-3   ALU execute
// 4     BEQ not taken
// 5     BNE not taken
// 6     JAL taken -> inst 36
//
// 7,8   flushed
//
// 36-39 ALU execute
// 40    BEQ not taken
// 41    BNE taken -> inst 60
//
// 42,43 flushed
//
// x20,x21,x22,x23 unchanged
//
// PC path:
// 0,4,8,12,16,20,24
// -> 144
// -> 148
// -> 152
// -> 156
// -> 160
// -> 164
// -> 240
initial
begin 
    reset = 1;              // Assert reset
    #30 reset = 0;          // Release reset after 30 ns
end

//================================================================================
// SIMULATION END
//================================================================================
initial
begin

    #500 $finish;
end

endmodule
