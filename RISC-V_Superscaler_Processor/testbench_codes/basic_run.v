`timescale 1ns / 1ps

//================================================================================
// RV32I SUPERSCALER PROCESSOR TESTBENCH
// Purpose: Basic ALU testing with immediate operations and register operations
// ISA: RISC-V 32-bit (RV32I)
// Test Type: ALU Timing Verification (5 ADDI + ALU operations)
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
    OP_IMM      = 7'b0010011,      // I-type: ADDI, SLLI, SLTI, etc.
    OP          = 7'b0110011,      // R-type: ADD, SUB, AND, OR, XOR, etc.
    MISC_MEM    = 7'b0001111,
    SYSTEM      = 7'b1110011;

//================================================================================
// RV32I FUNCTION CODES (FUNCT3 - 3 bits)
//================================================================================
parameter
    // ALU Operations (for both OP_IMM and OP)
    F3_ADDSUB   = 3'b000,           // ADD/SUB (funct7 differentiates)
    F3_SLL      = 3'b001,           // Shift Left Logical
    F3_SLT      = 3'b010,           // Set Less Than
    F3_SLTU     = 3'b011,           // Set Less Than Unsigned
    F3_XOR      = 3'b100,           // Bitwise XOR
    F3_SRLSRA   = 3'b101,           // Shift Right (funct7 differentiates)
    F3_OR       = 3'b110,           // Bitwise OR
    F3_AND      = 3'b111,           // Bitwise AND
    
    // Branch Operations
    F3_BEQ      = 3'b000,           // Branch if Equal
    F3_BNE      = 3'b001,           // Branch if Not Equal
    F3_BLT      = 3'b100,           // Branch if Less Than
    F3_BGE      = 3'b101,           // Branch if Greater Equal
    F3_BLTU     = 3'b110,           // Branch if Less Than (Unsigned)
    F3_BGEU     = 3'b111;           // Branch if Greater Equal (Unsigned)

//================================================================================
// RV32I FUNCT7 CODES (7 bits - for R-type and some I-type)
//================================================================================
parameter
    F7_ADD      = 7'b0000000,       // ADD, SLL, SRL, AND, OR, XOR
    F7_SUB      = 7'b0100000,       // SUB (instead of ADD)
    F7_SRA      = 7'b0100000;       // Shift Right Arithmetic (instead of SRL)

//================================================================================
// REGISTER NAMES (x0-x31)
//================================================================================
parameter
    x0  = 5'b00000,  // Zero Register
    x1  = 5'b00001,  // Return Address
    x2  = 5'b00010,  // Stack Pointer
    x3  = 5'b00011,
    x4  = 5'b00100,
    x5  = 5'b00101,
    x6  = 5'b00110,
    x7  = 5'b00111,
    x8  = 5'b01000,
    x9  = 5'b01001,
    x10 = 5'b01010,  // a0 - Function argument/return value
    x11 = 5'b01011,  // a1
    x12 = 5'b01100,  // a2
    x13 = 5'b01101,  // a3
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
// clk1 and clk2 are staggered for dual-issue pipeline
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
// MEMORY INITIALIZATION AND TEST SETUP
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
    // TEST SEQUENCE: 5 IMMEDIATE ADDITIONS (ADDI) - NO RAW HAZARDS
    //================================================================================
    // Test Goal: Verify timing and ALU operations with immediate operands
    // Instruction Format for I-type: {imm[11:0], rs1, funct3, rd, opcode}
    // Design: Each instruction uses DIFFERENT registers (no RAW hazards)
    // Hierarchical Path: RV32_SSP.FETCH.IMEM.MEM[address]
    //================================================================================
    
    // ========== INSTRUCTION 0 ==========
    // ADDI x3, x0, 10
    // Expected: x3 = 10
    RV32_SSP.FETCH.IMEM.MEM[0] <= {12'd10, x0, F3_ADDSUB, x3, OP_IMM};
    
    // ========== INSTRUCTION 1 ==========
    // ADDI x4, x0, 20 (reads x0, no dependency on x3)
    // Expected: x4 = 20
    RV32_SSP.FETCH.IMEM.MEM[1] <= {12'd20, x0, F3_ADDSUB, x4, OP_IMM};
    
    // ========== INSTRUCTION 2 ==========
    // ADDI x5, x0, 30 (reads x0, no dependency on x4)
    // Expected: x5 = 30
    RV32_SSP.FETCH.IMEM.MEM[2] <= {12'd30, x0, F3_ADDSUB, x5, OP_IMM};
    
    // ========== INSTRUCTION 3 ==========
    // ADDI x6, x0, 40 (reads x0, no dependency on x5)
    // Expected: x6 = 40
    RV32_SSP.FETCH.IMEM.MEM[3] <= {12'd40, x0, F3_ADDSUB, x6, OP_IMM};
    
    // ========== INSTRUCTION 4 ==========
    // ADDI x7, x0, 50 (reads x0, no dependency on x6)
    // Expected: x7 = 50
    RV32_SSP.FETCH.IMEM.MEM[4] <= {12'd50, x0, F3_ADDSUB, x7, OP_IMM};
    
    // Fill remaining instructions with NOPs
    for(k = 5; k < 256; k = k + 1)
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
