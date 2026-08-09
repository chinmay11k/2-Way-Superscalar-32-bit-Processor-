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
    //============================================================
        // REGISTER INITIALIZATION
        //============================================================
        
        for(i=0;i<32;i=i+1)
        begin
            RV32_SSP.DECODE.RF.REG[i] = 0;
        end
        
        // JALR target address
        RV32_SSP.DECODE.RF.REG[x26] = 20;
        
        //============================================================
        // EXPECTED FINAL REGISTER VALUES
        //============================================================
        //
        // x1  = 10
        // x2  = 20
        // x3  = 30
        // x4  = 40
        // x5  = 50
        //
        // x6-x9   = 0     (flushed)
        //
        // x10 = 100
        // x11 = 110
        // x12 = 120
        // x13 = 130
        // x14 = 140
        //
        // x15 = 150
        // x16 = 160
        // x17 = 170
        // x18 = 180
        // x19 = 190
        //
        // x20 = 200
        // x21 = 210
        // x22 = 220
        // x23 = 230
        // x24 = 240
        //
        // x29 = 206       (JALR link register)
        // x30 = 6         (JAL link register)
        //
        // Instructions 6-15 must not execute
        // Instructions 206-215 must not execute
        //
        //============================================================
        // INSTRUCTION MEMORY INITIALIZATION
        //============================================================
        
        //-------------------------
        // Main Program
        //-------------------------
        
        RV32_SSP.FETCH.IMEM.MEM[0] <= {12'd10,x0,F3_ADD_SUB,x1,OP_IMM};   // ADDI
        RV32_SSP.FETCH.IMEM.MEM[1] <= {12'd20,x0,F3_ADD_SUB,x2,OP_IMM};   // ADDI
        RV32_SSP.FETCH.IMEM.MEM[2] <= {12'd30,x0,F3_ADD_SUB,x3,OP_IMM};   // ADDI
        RV32_SSP.FETCH.IMEM.MEM[3] <= {12'd40,x0,F3_ADD_SUB,x4,OP_IMM};   // ADDI
        RV32_SSP.FETCH.IMEM.MEM[4] <= {12'd50,x0,F3_ADD_SUB,x5,OP_IMM};   // ADDI
        
        // JAL x30 -> 200
        // Replace JAL_IMM_200 with your J-type immediate encoding
        RV32_SSP.FETCH.IMEM.MEM[5] <= {JAL_IMM_200,x30,JAL};
        
        //-------------------------
        // Must Flush
        //-------------------------
        
        RV32_SSP.FETCH.IMEM.MEM[6]  <= {12'd111,x0,F3_ADD_SUB,x6 ,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[7]  <= {12'd222,x0,F3_ADD_SUB,x7 ,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[8]  <= {12'd333,x0,F3_ADD_SUB,x8 ,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[9]  <= {12'd444,x0,F3_ADD_SUB,x9 ,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[10] <= {12'd555,x0,F3_ADD_SUB,x10,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[11] <= {12'd666,x0,F3_ADD_SUB,x11,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[12] <= {12'd777,x0,F3_ADD_SUB,x12,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[13] <= {12'd888,x0,F3_ADD_SUB,x13,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[14] <= {12'd999,x0,F3_ADD_SUB,x14,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[15] <= {12'd123,x0,F3_ADD_SUB,x15,OP_IMM};
        
        //-------------------------
        // Return Address Target
        //-------------------------
        
        RV32_SSP.FETCH.IMEM.MEM[20] <= {12'd100,x0,F3_ADD_SUB,x10,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[21] <= {12'd110,x0,F3_ADD_SUB,x11,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[22] <= {12'd120,x0,F3_ADD_SUB,x12,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[23] <= {12'd130,x0,F3_ADD_SUB,x13,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[24] <= {12'd140,x0,F3_ADD_SUB,x14,OP_IMM};
        
        RV32_SSP.FETCH.IMEM.MEM[25] <= {12'd150,x0,F3_ADD_SUB,x15,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[26] <= {12'd160,x0,F3_ADD_SUB,x16,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[27] <= {12'd170,x0,F3_ADD_SUB,x17,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[28] <= {12'd180,x0,F3_ADD_SUB,x18,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[29] <= {12'd190,x0,F3_ADD_SUB,x19,OP_IMM};
        
        //-------------------------
        // Function Body @ 200
        //-------------------------
        
        RV32_SSP.FETCH.IMEM.MEM[200] <= {12'd200,x0,F3_ADD_SUB,x20,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[201] <= {12'd210,x0,F3_ADD_SUB,x21,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[202] <= {12'd220,x0,F3_ADD_SUB,x22,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[203] <= {12'd230,x0,F3_ADD_SUB,x23,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[204] <= {12'd240,x0,F3_ADD_SUB,x24,OP_IMM};
        
        // JALR x29,0(x26)
        RV32_SSP.FETCH.IMEM.MEM[205] <= {12'd0,x26,F3_ADD_SUB,x29,JALR};
        
        //-------------------------
        // Must Flush
        //-------------------------
        
        RV32_SSP.FETCH.IMEM.MEM[206] <= {12'd111,x0,F3_ADD_SUB,x1,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[207] <= {12'd222,x0,F3_ADD_SUB,x2,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[208] <= {12'd333,x0,F3_ADD_SUB,x3,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[209] <= {12'd444,x0,F3_ADD_SUB,x4,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[210] <= {12'd555,x0,F3_ADD_SUB,x5,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[211] <= {12'd666,x0,F3_ADD_SUB,x6,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[212] <= {12'd777,x0,F3_ADD_SUB,x7,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[213] <= {12'd888,x0,F3_ADD_SUB,x8,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[214] <= {12'd999,x0,F3_ADD_SUB,x9,OP_IMM};
        RV32_SSP.FETCH.IMEM.MEM[215] <= {12'd123,x0,F3_ADD_SUB,x10,OP_IMM};
        
        //-------------------------
        // Remaining Memory = NOP
        //-------------------------
        
        for(k=216;k<256;k=k+1)
        begin
            RV32_SSP.FETCH.IMEM.MEM[k] <= NOP;
        end
        
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
    #400 $finish;
end

endmodule
