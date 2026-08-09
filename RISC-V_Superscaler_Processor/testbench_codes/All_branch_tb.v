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
//================================================================================
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

//================================================================================
// MEMORY INITIALIZATION AND ALU TEST SETUP
//================================================================================
initial 
begin
    // Initialize all instruction memory with NOP
    for(j = 0; j < 256; j = j + 1)
    begin
        RV32_SSP.FETCH.IMEM.MEM[j] <= NOP;
    end
    for(i = 0; i < 32; i = i + 1)
        begin
            RV32_SSP.DECODE.RF.REG[i] <= 0;
        end
//expected
//        x1  = 10
//        x2  = 20
        
//        x4  = 40
//        x5  = 50
//        x6  = 60
        
//        x7  = 0      // flushed
//        x8  = 0      // flushed
//        x9  = 0      // flushed
        
//        x10 = 100
//        x11 = 110
//        x12 = 120
        
//        x13 = 130
//        x14 = 140
//        x15 = 150
        
//        x16 = 0      // flushed
//        x17 = 0      // flushed
//        x18 = 0      // flushed
        
//        x19 = 1900   // overwritten later
//        x20 = 2000   // overwritten later
//        x21 = 2100   // overwritten later
        
//        x22 = 2200
//        x23 = 2300
//        x24 = 240
        
//        x25 = 0      // flushed
//        x26 = 0      // flushed
//        x27 = 0      // flushed
        
//        x28 = 280
//        x29 = 290
//        x30 = 300
        
//        x3  = 31     // 30 + 1
//        x4  = 41     // 40 + 1
//        x5  = 51     // 50 + 1
        
//        x6  = 60     // branch-flushed update never executes
//        x7  = 0
//        x8  = 0
        
//        x9  = 900
//        x10 = 1000
//        x11 = 1100
        
//        x12 = 1200
//        x13 = 1300
//        x14 = 1400
        
//        x15 = 150    // branch-flushed assignment never executes
//        x16 = 0
//        x17 = 0
        
//        x18 = 1800
//        x19 = 1900
//        x20 = 2000
        
//        x21 = 2100
//        x22 = 2200
//        x23 = 2300
        
//        x24 = 240    // branch-flushed assignment never executes
//        x25 = 0
//        x26 = 0  
      #1
        RV32_SSP.DECODE.RF.REG[x1] = 10;
         RV32_SSP.DECODE.RF.REG[x2] = 20;

        // 0   ADDI x1,x0,10
        RV32_SSP.FETCH.IMEM.MEM[0]  <= {12'd300,x0,F3_ADD_SUB,x30,OP_IMM};
        
        // 1   ADDI x2,x0,20
        RV32_SSP.FETCH.IMEM.MEM[1]  <= {12'd310,x0,F3_ADD_SUB,x31,OP_IMM};
        
        // 2   ADDI x3,x0,30
        RV32_SSP.FETCH.IMEM.MEM[2]  <= {12'd30,x0,F3_ADD_SUB,x3,OP_IMM};
        
        // 3   BEQ x1,x2,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[3]  <= {7'd0,x2,x1,F3_BEQ,5'd6,BRANCH};
        
        // 4   ADDI x4,x0,40
        RV32_SSP.FETCH.IMEM.MEM[4]  <= {12'd40,x0,F3_ADD_SUB,x4,OP_IMM};
        
        // 5   ADDI x5,x0,50
        RV32_SSP.FETCH.IMEM.MEM[5]  <= {12'd50,x0,F3_ADD_SUB,x5,OP_IMM};
        
        // 6   ADDI x6,x0,60
        RV32_SSP.FETCH.IMEM.MEM[6]  <= {12'd60,x0,F3_ADD_SUB,x6,OP_IMM};
        
        // 7   BEQ x1,x1,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[7]  <= {7'd0,x1,x1,F3_BEQ,5'd6,BRANCH};
        
        // 8-10 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[8]  <= {12'd111,x0,F3_ADD_SUB,x7,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[9]  <= {12'd222,x0,F3_ADD_SUB,x8,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[10] <= {12'd333,x0,F3_ADD_SUB,x9,OP_IMM};
        
        // 13
        RV32_SSP.FETCH.IMEM.MEM[13] <= {12'd100,x0,F3_ADD_SUB,x10,OP_IMM};
        
        // 14
        RV32_SSP.FETCH.IMEM.MEM[14] <= {12'd110,x0,F3_ADD_SUB,x11,OP_IMM};
        
        
        
        // 15
        RV32_SSP.FETCH.IMEM.MEM[15] <= {12'd120,x0,F3_ADD_SUB,x12,OP_IMM};
        
        // 16 BNE x1,x1,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[16] <= {7'd0,x1,x1,F3_BNE,5'd6,BRANCH};
        
        // 17
        RV32_SSP.FETCH.IMEM.MEM[17] <= {12'd130,x0,F3_ADD_SUB,x13,OP_IMM};
        
        // 18
        RV32_SSP.FETCH.IMEM.MEM[18] <= {12'd140,x0,F3_ADD_SUB,x14,OP_IMM};
        
        // 19
        RV32_SSP.FETCH.IMEM.MEM[19] <= {12'd150,x0,F3_ADD_SUB,x15,OP_IMM};
        
        // 20 BNE x1,x2,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[20] <= {7'd0,x2,x1,F3_BNE,5'd6,BRANCH};
        
        // 21-23 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[21] <= {12'd111,x0,F3_ADD_SUB,x16,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[22] <= {12'd222,x0,F3_ADD_SUB,x17,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[23] <= {12'd333,x0,F3_ADD_SUB,x18,OP_IMM};
        
        // 26
        RV32_SSP.FETCH.IMEM.MEM[26] <= {12'd190,x0,F3_ADD_SUB,x19,OP_IMM};
        
        // 27
        RV32_SSP.FETCH.IMEM.MEM[27] <= {12'd200,x0,F3_ADD_SUB,x20,OP_IMM};
        
        // 28
        RV32_SSP.FETCH.IMEM.MEM[28] <= {12'd210,x0,F3_ADD_SUB,x21,OP_IMM};
        
        // 29 BLT x2,x1,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[29] <= {7'd0,x1,x2,F3_BLT,5'd6,BRANCH};
        
        // 30
        RV32_SSP.FETCH.IMEM.MEM[30] <= {12'd220,x0,F3_ADD_SUB,x22,OP_IMM};
        
        // 31
        RV32_SSP.FETCH.IMEM.MEM[31] <= {12'd230,x0,F3_ADD_SUB,x23,OP_IMM};
        
        // 32
        RV32_SSP.FETCH.IMEM.MEM[32] <= {12'd240,x0,F3_ADD_SUB,x24,OP_IMM};
        
        // 33 BLT x1,x2,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[33] <= {7'd0,x2,x1,F3_BLT,5'd6,BRANCH};
        
        // 34-36 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[34] <= {12'd111,x0,F3_ADD_SUB,x25,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[35] <= {12'd222,x0,F3_ADD_SUB,x26,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[36] <= {12'd333,x0,F3_ADD_SUB,x27,OP_IMM};
        
        // 39
        RV32_SSP.FETCH.IMEM.MEM[39] <= {12'd280,x0,F3_ADD_SUB,x28,OP_IMM};
        
        // 40
        RV32_SSP.FETCH.IMEM.MEM[40] <= {12'd290,x0,F3_ADD_SUB,x29,OP_IMM};
        
        // 41
        RV32_SSP.FETCH.IMEM.MEM[41] <= {12'd300,x0,F3_ADD_SUB,x30,OP_IMM};
        
        // 42 BGE x1,x2,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[42] <= {7'd0,x2,x1,F3_BGE,5'd6,BRANCH};
        
        // 43
        RV32_SSP.FETCH.IMEM.MEM[43] <= {12'd1,x3,F3_ADD_SUB,x3,OP_IMM};
        
        // 44
        RV32_SSP.FETCH.IMEM.MEM[44] <= {12'd1,x4,F3_ADD_SUB,x4,OP_IMM};
        
        // 45
        RV32_SSP.FETCH.IMEM.MEM[45] <= {12'd1,x5,F3_ADD_SUB,x5,OP_IMM};
        
        // 46 BGE x2,x1,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[46] <= {7'd0,x1,x2,F3_BGE,5'd6,BRANCH};
        
        // 47-49 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[47] <= {12'd111,x0,F3_ADD_SUB,x6,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[48] <= {12'd222,x0,F3_ADD_SUB,x7,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[49] <= {12'd333,x0,F3_ADD_SUB,x8,OP_IMM};
        
        // 52
        RV32_SSP.FETCH.IMEM.MEM[52] <= {12'd900,x0,F3_ADD_SUB,x9,OP_IMM};
        
        // 53
        RV32_SSP.FETCH.IMEM.MEM[53] <= {12'd1000,x0,F3_ADD_SUB,x10,OP_IMM};
        
        // 54
        RV32_SSP.FETCH.IMEM.MEM[54] <= {12'd1100,x0,F3_ADD_SUB,x11,OP_IMM};
        
        // 55 BLTU x2,x1,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[55] <= {7'd0,x1,x2,F3_BLTU,5'd6,BRANCH};
        
        // 56
        RV32_SSP.FETCH.IMEM.MEM[56] <= {12'd1200,x0,F3_ADD_SUB,x12,OP_IMM};
        
        // 57
        RV32_SSP.FETCH.IMEM.MEM[57] <= {12'd1300,x0,F3_ADD_SUB,x13,OP_IMM};
        
        // 58
        RV32_SSP.FETCH.IMEM.MEM[58] <= {12'd1400,x0,F3_ADD_SUB,x14,OP_IMM};
        
        // 59 BLTU x1,x2,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[59] <= {7'd0,x2,x1,F3_BLTU,5'd6,BRANCH};
        
        // 60-62 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[60] <= {12'd111,x0,F3_ADD_SUB,x15,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[61] <= {12'd222,x0,F3_ADD_SUB,x16,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[62] <= {12'd333,x0,F3_ADD_SUB,x17,OP_IMM};
        
        // 65
        RV32_SSP.FETCH.IMEM.MEM[65] <= {12'd1800,x0,F3_ADD_SUB,x18,OP_IMM};
        
        // 66
        RV32_SSP.FETCH.IMEM.MEM[66] <= {12'd1900,x0,F3_ADD_SUB,x19,OP_IMM};
        
        // 67
        RV32_SSP.FETCH.IMEM.MEM[67] <= {12'd2000,x0,F3_ADD_SUB,x20,OP_IMM};
        
        // 68 BGEU x1,x2,+6 (NOT TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[68] <= {7'd0,x2,x1,F3_BGEU,5'd6,BRANCH};
        
        // 69
        RV32_SSP.FETCH.IMEM.MEM[69] <= {12'd211,x0,F3_ADD_SUB,x21,OP_IMM};
        
        // 70
        RV32_SSP.FETCH.IMEM.MEM[70] <= {12'd225,x0,F3_ADD_SUB,x22,OP_IMM};
        
        // 71
        RV32_SSP.FETCH.IMEM.MEM[71] <= {12'd239,x0,F3_ADD_SUB,x23,OP_IMM};
        
        // 72 BGEU x2,x1,+6 (TAKEN)
        RV32_SSP.FETCH.IMEM.MEM[72] <= {7'd0,x1,x2,F3_BGEU,5'd6,BRANCH};
        
        // 73-75 FLUSH
        RV32_SSP.FETCH.IMEM.MEM[73] <= {12'd111,x0,F3_ADD_SUB,x24,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[74] <= {12'd222,x0,F3_ADD_SUB,x25,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[75] <= {12'd333,x0,F3_ADD_SUB,x26,OP_IMM};
        
        
        RV32_SSP.FETCH.IMEM.MEM[78] <= {12'd279,x0,F3_ADD_SUB,x27,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[79] <= {12'd286,x0,F3_ADD_SUB,x28,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[80] <= {12'd299,x0,F3_ADD_SUB,x29,OP_IMM};
        
        
      end

//====================== ==========================================================
// RESET GENERATION
//================================================================================
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
    #1000 $finish;
end

endmodule
