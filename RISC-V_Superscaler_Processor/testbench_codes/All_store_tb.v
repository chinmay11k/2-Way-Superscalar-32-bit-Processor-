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
            RV32_SSP.DECODE.RF.REG[i] <= i;
        end
      #1
      RV32_SSP.DECODE.RF.REG[x20] = 0;      
      RV32_SSP.DECODE.RF.REG[x21] = 32'h000000AA;
      RV32_SSP.DECODE.RF.REG[x22] = 32'h00001234;
      RV32_SSP.DECODE.RF.REG[x23] = 32'hDEADBEEF;
      RV32_SSP.DECODE.RF.REG[x24] = 32'h00000055;
      RV32_SSP.DECODE.RF.REG[x25] = 32'h00005678;// Expected:
        // MEM[1]  updated by SB
        // MEM[3]  updated by SH
        // MEM[5]  updated by SW
        // MEM[7]  updated by SB
        // MEM[10] updated by SH
        #1;
        RV32_SSP.FETCH.IMEM.MEM[0] <= {7'd0, x21, x20, F3_SB, 5'd4,  STORE}; // SB x21, 4(x20)
        
        RV32_SSP.FETCH.IMEM.MEM[1] <= {12'd5, x10, F3_ADD_SUB, x11, OP_IMM};  // ADDI
        
        RV32_SSP.FETCH.IMEM.MEM[2] <= {7'd0, x22, x20, F3_SH, 5'd12, STORE}; // SH x22,12(x20)
        
        RV32_SSP.FETCH.IMEM.MEM[3] <= {12'd7, x12, F3_XOR, x13, OP_IMM};      // XORI
        
        RV32_SSP.FETCH.IMEM.MEM[4] <= {7'd0, x23, x20, F3_SW, 5'd20, STORE}; // SW x23,20(x20)
        
        RV32_SSP.FETCH.IMEM.MEM[5] <= {12'd3, x14, F3_OR, x15, OP_IMM};       // ORI
        
        RV32_SSP.FETCH.IMEM.MEM[6] <= {7'd0, x24, x20, F3_SB, 5'd28, STORE}; // SB x24,28(x20)
        
        RV32_SSP.FETCH.IMEM.MEM[7] <= {12'd1, x16, F3_AND, x17, OP_IMM};      // ANDI
        
        RV32_SSP.FETCH.IMEM.MEM[8] <= {7'd1, x25, x20, F3_SH, 5'd8, STORE};  // SH x25,40(x20)
                                                                             // imm={7'd1,5'd8}=40
        
        RV32_SSP.FETCH.IMEM.MEM[9] <= NOP;
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
    #200 $finish;
end

endmodule
