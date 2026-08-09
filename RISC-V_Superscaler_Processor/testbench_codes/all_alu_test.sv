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

//================================================================================
// RV32I INSTRUCTION PARAMETERS (OPCODES)
//================================================================================
parameter
    // Major Opcodes (7 bits)
    LUI         = 7'b0110111,
    AUIPC       = 7'b0010111,
    JAL         = 7'b1101111,
    JALR        = 7'b1100111,
    BRANCH      = 7'b1100011,
    LOAD        = 7'b0000011,
    STORE       = 7'b0100011,
    OP_IMM      = 7'b0010011,
    OP          = 7'b0110011,
    MISC_MEM    = 7'b0001111,
    SYSTEM      = 7'b1110011;

//================================================================================
// RV32I FUNCTION CODES (FUNCT3 - 3 bits)
//================================================================================
parameter
    F3_ADDSUB   = 3'b000,
    F3_SLL      = 3'b001,
    F3_SLT      = 3'b010,
    F3_SLTU     = 3'b011,
    F3_XOR      = 3'b100,
    F3_SRLSRA   = 3'b101,
    F3_OR       = 3'b110,
    F3_AND      = 3'b111;

//================================================================================
// RV32I FUNCT7 CODES (7 bits - for R-type and shift immediates)
//================================================================================
parameter
    F7_ADD      = 7'b0000000,
    F7_SUB      = 7'b0100000,
    F7_SRA      = 7'b0100000;

//================================================================================
// REGISTER NAMES (x0-x31)
//================================================================================
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

//================================================================================
// NOP INSTRUCTION (addi x0, x0, 0)
//================================================================================
parameter
    NOP = 32'h00000013;

//================================================================================
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
    
    #1;  // Small delay before writing instructions

    //================================================================================
    // TEST SETUP: REGISTER FILE INITIALIZATION
    //================================================================================
    // Initialize each register with its index value (xN = N).
    // This allows easy cross-checking of actual values in simulation.
    //================================================================================
    for(i = 0; i < 32; i = i + 1)
    begin
        RV32_SSP.DECODE.RF.REG[i] <= i;
    end

    //================================================================================
    // TEST SEQUENCE: ALL REGISTER-REGISTER ALU OPERATIONS WITHOUT HAZARDS
    //================================================================================
    // Each instruction reads from two different source registers and writes to a
    // sequential destination register. No instruction depends on the result of
    // any prior instruction.
    //================================================================================

    // Expected:
    //  x3  = x13 + x14 = 13 + 14 = 27
    //  x4  = x15 - x16 = 15 - 16 = -1
    //  x5  = x17 << x18 = 17 << 18 = 0 (shift amount high, source too large for x0?)
    //  x6  = x19 < x20 ? 1 : 0 = 1
    //  x7  = x21 <u x22 ? 1 : 0 = 1
    //  x8  = x23 ^ x24 = 23 ^ 24 = 15
    //  x9  = x25 >> x26 = 25 >> 26 = 0
    //  x10 = x27 >>> x28 = 27 >>> 28 = 0
    //  x11 = x29 | x30 = 29 | 30 = 31
    //  x12 = x31 & x1  = 31 & 1  = 1

    RV32_SSP.FETCH.IMEM.MEM[0]  <= {F7_ADD, x13, x14, F3_ADDSUB, x3,  OP}; // ADD  x3,  x13, x14
    RV32_SSP.FETCH.IMEM.MEM[1]  <= {F7_SUB, x15, x16, F3_ADDSUB, x4,  OP}; // SUB  x4,  x15, x16
    RV32_SSP.FETCH.IMEM.MEM[2]  <= {F7_ADD, x17, x18, F3_SLL,    x5,  OP}; // SLL  x5,  x17, x18
    RV32_SSP.FETCH.IMEM.MEM[3]  <= {F7_ADD, x19, x20, F3_SLT,    x6,  OP}; // SLT  x6,  x19, x20
    RV32_SSP.FETCH.IMEM.MEM[4]  <= {F7_ADD, x21, x22, F3_SLTU,   x7,  OP}; // SLTU x7,  x21, x22
    RV32_SSP.FETCH.IMEM.MEM[5]  <= {F7_ADD, x23, x24, F3_XOR,    x8,  OP}; // XOR  x8,  x23, x24
    RV32_SSP.FETCH.IMEM.MEM[6]  <= {F7_ADD, x25, x26, F3_SRLSRA, x9,  OP}; // SRL  x9,  x25, x26
    RV32_SSP.FETCH.IMEM.MEM[7]  <= {F7_SRA,  x27, x28, F3_SRLSRA, x10, OP}; // SRA  x10, x27, x28
    RV32_SSP.FETCH.IMEM.MEM[8]  <= {F7_ADD, x29, x30, F3_OR,     x11, OP}; // OR   x11, x29, x30
    RV32_SSP.FETCH.IMEM.MEM[9]  <= {F7_ADD, x31, x1,  F3_AND,    x12, OP}; // AND  x12, x31, x1

    // Fill remaining instructions with NOPs
    for(k = 10; k < 256; k = k + 1)
    begin
        RV32_SSP.FETCH.IMEM.MEM[k] <= NOP;
    end

end

//================================================================================
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
    #500 $finish;
end

endmodule
