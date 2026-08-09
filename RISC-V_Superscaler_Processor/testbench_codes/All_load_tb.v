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
// Clear entire memory first
        for(i=0;i<128;i=i+1)
            RV32_SSP.MEM_STAGE_B.dmem.MEM[i] = 8'h00;
        
        // --------------------------------------------------
        // Address 4 : LB/LBU negative test
        // value = 0x80
        // --------------------------------------------------
        RV32_SSP.MEM_STAGE_B.dmem.MEM[4] = 8'h80;
        
        // --------------------------------------------------
        // Address 8 : LH/LHU negative test
        // value = 16'h8001
        // little endian
        // --------------------------------------------------
        RV32_SSP.MEM_STAGE_B.dmem.MEM[8] = 8'h01;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[9] = 8'h80;
        
        // --------------------------------------------------
        // Address 12 : LW test
        // value = 32'hDEADBEEF
        // little endian
        // --------------------------------------------------
        RV32_SSP.MEM_STAGE_B.dmem.MEM[12] = 8'hEF;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[13] = 8'hBE;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[14] = 8'hAD;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[15] = 8'hDE;
        
        // --------------------------------------------------
        // Address 16 : LB positive test
        // value = 0x7F
        // --------------------------------------------------
        RV32_SSP.MEM_STAGE_B.dmem.MEM[16] = 8'h7F;
        
        // --------------------------------------------------
        // Address 20 : LH positive test
        // value = 16'h7FFF
        // little endian
        // --------------------------------------------------
        RV32_SSP.MEM_STAGE_B.dmem.MEM[20] = 8'hFF;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[21] = 8'h7F;        RV32_SSP.DECODE.RF.REG[x20] = 0;
        
        
        RV32_SSP.DECODE.RF.REG[20] <= 0;

        // ------------------------------------------------------------------
        // EXPECTED RESULTS
        // ------------------------------------------------------------------
        //
        // x3  = LB  from addr 4  = 0xFFFFFF80
        // x4  = LBU from addr 4  = 0x00000080
        //
        // x5  = LH  from addr 8  = 0xFFFF8001
        // x6  = LHU from addr 8  = 0x00008001
        //
        // x7  = LW  from addr 12 = 0xDEADBEEF
        //
        // x8  = LB  from addr 16 = 0x0000007F
        //
        // x9  = LH  from addr 20 = 0x00007FFF
        //
        // ------------------------------------------------------------------
        // PROGRAM (NO HAZARDS)
        // ------------------------------------------------------------------
        
        // LB x3,4(x20)
        RV32_SSP.FETCH.IMEM.MEM[0]  <= {12'd4 ,x20,F3_LB ,x3 ,LOAD};
        
        // ADDI x21,x1,100
        RV32_SSP.FETCH.IMEM.MEM[1]  <= {12'd100,x1,F3_ADD_SUB,x21,OP_IMM};
        
//         LBU x4,4(x20)
        RV32_SSP.FETCH.IMEM.MEM[2]  <= {12'd4 ,x20,F3_LBU,x4 ,LOAD};
        
        // XORI x22,x2,55
        RV32_SSP.FETCH.IMEM.MEM[3]  <= {12'd55,x2,F3_XOR,x22,OP_IMM};
        
        // LH x5,8(x20)
        RV32_SSP.FETCH.IMEM.MEM[4]  <= {12'd8 ,x20,F3_LH ,x5 ,LOAD};
        
        // ORI x23,x10,7
        RV32_SSP.FETCH.IMEM.MEM[5]  <= {12'd7 ,x10,F3_OR,x23,OP_IMM};
        
        // LHU x6,8(x20)
        RV32_SSP.FETCH.IMEM.MEM[6]  <= {12'd8 ,x20,F3_LHU,x6 ,LOAD};
        
        // ANDI x24,x11,15
        RV32_SSP.FETCH.IMEM.MEM[7]  <= {12'd15,x11,F3_AND,x24,OP_IMM};
        
        // LW x7,12(x20)
        RV32_SSP.FETCH.IMEM.MEM[8]  <= {12'd12,x20,F3_LW ,x7 ,LOAD};
        
        // ADDI x25,x12,9
        RV32_SSP.FETCH.IMEM.MEM[9]  <= {12'd9 ,x12,F3_ADD_SUB,x25,OP_IMM};
        
        // LB x8,16(x20)
        RV32_SSP.FETCH.IMEM.MEM[10] <= {12'd16,x20,F3_LB ,x8 ,LOAD};
        
        // XORI x26,x13,3
        RV32_SSP.FETCH.IMEM.MEM[11] <= {12'd3 ,x13,F3_XOR,x26,OP_IMM};
        
        // LH x9,20(x20)
        RV32_SSP.FETCH.IMEM.MEM[12] <= {12'd20,x20,F3_LH ,x9 ,LOAD};
        
        // ORI x27,x14,16
        RV32_SSP.FETCH.IMEM.MEM[13] <= {12'd16,x14,F3_OR,x27,OP_IMM};
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
