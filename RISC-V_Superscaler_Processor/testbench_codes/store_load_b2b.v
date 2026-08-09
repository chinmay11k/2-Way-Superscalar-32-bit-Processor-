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
//    for(i = 0; i < 32; i = i + 1)
//        begin
//            RV32_SSP.DECODE.RF.REG[i] <= 0;
//        end
    #1;
        RV32_SSP.DECODE.RF.REG[x20] = 0;      // base
 
        RV32_SSP.DECODE.RF.REG[x21] = 8'hAA;
        RV32_SSP.DECODE.RF.REG[x22] = 16'h1234;
        RV32_SSP.DECODE.RF.REG[x23] = 32'hDEADBEEF;
        RV32_SSP.DECODE.RF.REG[x24] = 8'h55;
        RV32_SSP.DECODE.RF.REG[x25] = 16'h5678;
        RV32_SSP.DECODE.RF.REG[x26] = 32'hCAFEBABE;       
        
        // LB source
        RV32_SSP.MEM_STAGE_B.dmem.MEM[4]  = 8'h80;
        
        // LH source
        RV32_SSP.MEM_STAGE_B.dmem.MEM[8]  = 8'h01;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[9]  = 8'h80;
        
        // LW source
        RV32_SSP.MEM_STAGE_B.dmem.MEM[12] = 8'hEF;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[13] = 8'hBE;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[14] = 8'hAD;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[15] = 8'hDE;
        
        // LBU source
        RV32_SSP.MEM_STAGE_B.dmem.MEM[20] = 8'h7F;
        
        // LHU source
        RV32_SSP.MEM_STAGE_B.dmem.MEM[24] = 8'hFF;
        RV32_SSP.MEM_STAGE_B.dmem.MEM[25] = 8'h7F;
        
        //==================================================
        // LOAD STORE LOAD STORE ...
        //==================================================
        
        // LB  x1,4(x20)
        RV32_SSP.FETCH.IMEM.MEM[0]  <= {12'd4 ,x20,F3_LB ,x1 ,LOAD};
        
        // SB  x21,40(x20)
        RV32_SSP.FETCH.IMEM.MEM[1]  <= {7'd1,x21,x20,F3_SB,5'd8,STORE};    // 40
        
        // LH  x2,8(x20)
        RV32_SSP.FETCH.IMEM.MEM[2]  <= {12'd8 ,x20,F3_LH ,x2 ,LOAD};
        
        // SH  x22,44(x20)
        RV32_SSP.FETCH.IMEM.MEM[3]  <= {7'd1,x22,x20,F3_SH,5'd12,STORE};   // 44
        
        // LW  x3,12(x20)
        RV32_SSP.FETCH.IMEM.MEM[4]  <= {12'd12,x20,F3_LW ,x3 ,LOAD};
        
        // SW  x23,48(x20)
        RV32_SSP.FETCH.IMEM.MEM[5]  <= {7'd1,x23,x20,F3_SW,5'd16,STORE};   // 48
        
        // LBU x4,20(x20)
        RV32_SSP.FETCH.IMEM.MEM[6]  <= {12'd20,x20,F3_LBU,x4 ,LOAD};
        
        // SB  x24,52(x20)
        RV32_SSP.FETCH.IMEM.MEM[7]  <= {7'd1,x24,x20,F3_SB,5'd20,STORE};   // 52
        
        // LHU x5,24(x20)
        RV32_SSP.FETCH.IMEM.MEM[8]  <= {12'd24,x20,F3_LHU,x5 ,LOAD};
        
        // SH  x25,56(x20)
        RV32_SSP.FETCH.IMEM.MEM[9]  <= {7'd1,x25,x20,F3_SH,5'd24,STORE};   // 56
        
        // LW  x6,12(x20)
        RV32_SSP.FETCH.IMEM.MEM[10] <= {12'd12,x20,F3_LW,x6,LOAD};
        
        // SW  x26,60(x20)
        RV32_SSP.FETCH.IMEM.MEM[11] <= {7'd1,x26,x20,F3_SW,5'd28,STORE};   // 60
        
        
        
        
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

    #250 $finish;
end

endmodule
