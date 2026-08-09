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
//====================================================
// Register Initialization
//====================================================

for(i=0;i<32;i=i+1)
begin
    RV32_SSP.DECODE.RF.REG[i] = i;
end

//====================================================
// Data Memory Initialization
//====================================================

// LOAD targets

RV32_SSP.MEM_STAGE_B.dmem.MEM[11] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[12] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[13] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[14] = 8'h80;

RV32_SSP.MEM_STAGE_B.dmem.MEM[15] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[16] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[17] = 8'h10;
RV32_SSP.MEM_STAGE_B.dmem.MEM[18] = 8'h08;

RV32_SSP.MEM_STAGE_B.dmem.MEM[19] = 8'hEF;
RV32_SSP.MEM_STAGE_B.dmem.MEM[20] = 8'hBE;
RV32_SSP.MEM_STAGE_B.dmem.MEM[21] = 8'hAD;
RV32_SSP.MEM_STAGE_B.dmem.MEM[22] = 8'hDE;

RV32_SSP.MEM_STAGE_B.dmem.MEM[23] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[24] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[25] = 8'h0;
RV32_SSP.MEM_STAGE_B.dmem.MEM[26] = 8'h7F;

//====================================================
// Expected
//====================================================
//
// x1 = 11
// x2 = FFFFFF80
//
// x3 = 15
// x4 = FFFF8001
//
// x5 = 19
// x6 = DEADBEEF
//
// x7 = 23
// x8 = 0000007F
//
// x9  = 27
// MEM[27] = 10 (SB)
//
// x11 = 31
// MEM[31] = 0x000C (SH)
//
// x13 = 35
// MEM[35] = 14 (SW)
//
// x15 = 39
// MEM[39] = 16 (SB)
//
//====================================================
// Instruction Memory
//====================================================

//----------------------------------------------------
// LOAD ADDRESS RAW TESTS
//----------------------------------------------------

// 0 : x1=11
RV32_SSP.FETCH.IMEM.MEM[0] <= {F7_ADD,x6,x5,F3_ADD_SUB,x1,OP};

RV32_SSP.FETCH.IMEM.MEM[1] <= {F7_ADD,x18,x17,F3_ADD_SUB,x21,OP};
RV32_SSP.FETCH.IMEM.MEM[2] <= {F7_ADD,x20,x19,F3_ADD_SUB,x22,OP};
RV32_SSP.FETCH.IMEM.MEM[3] <= {F7_ADD,x22,x21,F3_ADD_SUB,x23,OP};
RV32_SSP.FETCH.IMEM.MEM[4] <= {F7_ADD,x24,x23,F3_ADD_SUB,x24,OP};
RV32_SSP.FETCH.IMEM.MEM[5] <= {F7_ADD,x26,x25,F3_ADD_SUB,x25,OP};

// 6 : LB 0(x1)
RV32_SSP.FETCH.IMEM.MEM[6] <= {12'd0,x1,F3_LB,x2,LOAD};

// 7 : x3=15
RV32_SSP.FETCH.IMEM.MEM[7] <= {F7_ADD,x8,x7,F3_ADD_SUB,x3,OP};

RV32_SSP.FETCH.IMEM.MEM[8]  <= {F7_ADD,x28,x27,F3_ADD_SUB,x26,OP};
RV32_SSP.FETCH.IMEM.MEM[9]  <= {F7_ADD,x30,x29,F3_ADD_SUB,x27,OP};
RV32_SSP.FETCH.IMEM.MEM[10] <= {F7_ADD,x18,x11,F3_ADD_SUB,x28,OP};

// 11 : LH 0(x3)
RV32_SSP.FETCH.IMEM.MEM[11] <= {12'd0,x3,F3_LH,x4,LOAD};

// 12 : x5=19
RV32_SSP.FETCH.IMEM.MEM[12] <= {F7_ADD,x10,x9,F3_ADD_SUB,x5,OP};

RV32_SSP.FETCH.IMEM.MEM[13] <= {F7_ADD,x22,x21,F3_ADD_SUB,x29,OP};

// 14 : LW 0(x5)
RV32_SSP.FETCH.IMEM.MEM[14] <= {12'd0,x5,F3_LW,x6,LOAD};

// 15 : x7=23
RV32_SSP.FETCH.IMEM.MEM[15] <= {F7_ADD,x12,x11,F3_ADD_SUB,x7,OP};

// 16 : LBU 0(x7)
RV32_SSP.FETCH.IMEM.MEM[16] <= {12'd0,x7,F3_LBU,x8,LOAD};

//----------------------------------------------------
// STORE ADDRESS RAW TESTS
//----------------------------------------------------

// 17 : x9=27
RV32_SSP.FETCH.IMEM.MEM[17] <= {F7_ADD,x14,x13,F3_ADD_SUB,x9,OP};

RV32_SSP.FETCH.IMEM.MEM[18] <= {F7_ADD,x24,x17,F3_ADD_SUB,x30,OP};
RV32_SSP.FETCH.IMEM.MEM[19] <= {F7_ADD,x25,x18,F3_ADD_SUB,x29,OP};
RV32_SSP.FETCH.IMEM.MEM[20] <= {F7_ADD,x26,x19,F3_ADD_SUB,x28,OP};
RV32_SSP.FETCH.IMEM.MEM[21] <= {F7_ADD,x27,x20,F3_ADD_SUB,x27,OP};
RV32_SSP.FETCH.IMEM.MEM[22] <= {F7_ADD,x28,x21,F3_ADD_SUB,x26,OP};

// 23 : SB x10,0(x9)
RV32_SSP.FETCH.IMEM.MEM[23] <= {7'd0,x10,x9,F3_SB,5'd0,STORE};

// 24 : x11=31
RV32_SSP.FETCH.IMEM.MEM[24] <= {F7_ADD,x16,x15,F3_ADD_SUB,x11,OP};

RV32_SSP.FETCH.IMEM.MEM[25] <= {F7_ADD,x20,x19,F3_ADD_SUB,x25,OP};
RV32_SSP.FETCH.IMEM.MEM[26] <= {F7_ADD,x22,x21,F3_ADD_SUB,x24,OP};
RV32_SSP.FETCH.IMEM.MEM[27] <= {F7_ADD,x24,x23,F3_ADD_SUB,x23,OP};

// 28 : SH x12,0(x11)
RV32_SSP.FETCH.IMEM.MEM[28] <= {7'd0,x12,x11,F3_SH,5'd0,STORE};

// 29 : x13=35
RV32_SSP.FETCH.IMEM.MEM[29] <= {F7_ADD,x18,x17,F3_ADD_SUB,x13,OP};

RV32_SSP.FETCH.IMEM.MEM[30] <= {F7_ADD,x26,x25,F3_ADD_SUB,x22,OP};

// 31 : SW x14,0(x13)
RV32_SSP.FETCH.IMEM.MEM[31] <= {7'd0,x14,x13,F3_SW,5'd0,STORE};

// 32 : x15=39
RV32_SSP.FETCH.IMEM.MEM[32] <= {F7_ADD,x20,x19,F3_ADD_SUB,x15,OP};

// 33 : SB x16,0(x15)
RV32_SSP.FETCH.IMEM.MEM[33] <= {7'd0,x16,x15,F3_SB,5'd0,STORE};

for(k=34;k<256;k=k+1)
begin
    RV32_SSP.FETCH.IMEM.MEM[k] <= NOP;
end

end


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

    #250 $finish;
end

endmodule
