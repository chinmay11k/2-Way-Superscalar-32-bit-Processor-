`timescale 1ns / 1ps
module RV32_top(

input clk1,
input clk2,
input reset

);

//====================================================
// FETCH -> DECODE
//====================================================

wire [31:0] IF_ID_IR_0;
wire [31:0] IF_ID_IR_1;

wire [31:0] IF_ID_PC_0;
wire [31:0] IF_ID_PC_1;

//====================================================
// DECODE -> EXECUTE
//====================================================

wire [31:0] ID_EX_IR_A;
wire [31:0] ID_EX_PC_A;
wire [31:0] ID_EX_X0_A;
wire [31:0] ID_EX_X1_A;
wire [31:0] ID_EX_IMM_A;
wire [2:0]  ID_EX_TYPE_A;

wire [31:0] ID_EX_IR_B;
wire [31:0] ID_EX_PC_B;
wire [31:0] ID_EX_X0_B;
wire [31:0] ID_EX_X1_B;
wire [31:0] ID_EX_IMM_B;
wire [2:0]  ID_EX_TYPE_B;
wire        ID_EX_AGE_A;
wire        ID_EX_AGE_B;

wire        EX_MEM_AGE_A;
wire        EX_MEM_AGE_B;

wire        MEM_WB_AGE_A;
wire        MEM_WB_AGE_B;
wire [2:0]  type0;
wire [2:0]  type1;
wire branch_taken;
//====================================================
// EXECUTE -> MEMORY
//====================================================

wire [31:0] EX_MEM_IR_A;
wire [31:0] EX_MEM_ALUout_A;
wire [2:0]  EX_MEM_TYPE_A;

wire [31:0] EX_MEM_IR_B;
wire [31:0] EX_MEM_ALUout_B;
wire [31:0] EX_MEM_X1_B;
wire [2:0]  EX_MEM_TYPE_B;

//====================================================
// MEMORY -> WRITEBACK
//====================================================

wire [31:0] MEM_WB_IR_A;
wire [31:0] MEM_WB_ALUout_A;
wire [2:0]  MEM_WB_TYPE_A;

wire [31:0] MEM_WB_IR_B;
wire [31:0] MEM_WB_ALUout_B;
wire [31:0] MEM_WB_LMD_B;
wire [2:0]  MEM_WB_TYPE_B;

//====================================================
// WB OUTPUTS
//====================================================

wire wb_en_A;
wire [4:0] wb_rd_A;
wire [31:0] wb_data_A;

wire wb_en_B;
wire [4:0] wb_rd_B;
wire [31:0] wb_data_B;
wire        wb_age_A;
wire        wb_age_B;

//====================================================
// HAZARD SIGNALS
//====================================================

//wire ID_ID_hazard;
//wire ID_EX_hazard;
//wire ID_MEM_hazard;
//wire ID_WB_hazard;

wire hazard_ID_stall;
wire hazard_stall;

//====================================================
// CONTROL SIGNALS
//====================================================

wire branched;
wire [31:0] next_pc;

wire stall_II;

wire stall_IF;
wire stall_ID;
wire stall_EX;

//====================================================
// TYPE WIRES FOR HAZARD UNIT
//====================================================


//====================================================
// STALL LOGIC
//====================================================

assign stall_IF =
            hazard_stall |
            stall_II ;

assign stall_ID =
            hazard_stall ;

assign stall_EX = 1'b0;

//====================================================
// FETCH STAGE
//====================================================

fetch_stage FETCH(

    .clk(clk1),
    .reset(reset),
    .hazard_ID_stall(hazard_ID_stall),

    .stall_IF(stall_IF),

    .branched(branched),
    .branch_target(next_pc),

    .IF_ID_IR_0(IF_ID_IR_0),
    .IF_ID_IR_1(IF_ID_IR_1),

    .IF_ID_PC_0(IF_ID_PC_0),
    .IF_ID_PC_1(IF_ID_PC_1)

);

//====================================================
// DECODE / ISSUE STAGE
//====================================================

decode_issue_stage DECODE(

    .clk2(clk2),
    .clk1(clk1),
    .reset(reset),

    .stall_ID(stall_ID),
    .hazard_ID_stall(hazard_ID_stall),

    .branched(branched),

    .stall_II(stall_II),

    .IF_ID_IR_0(IF_ID_IR_0),
    .IF_ID_IR_1(IF_ID_IR_1),

    .IF_ID_PC_0(IF_ID_PC_0),
    .IF_ID_PC_1(IF_ID_PC_1),

    .wb_en_A(wb_en_A),
    .wb_rd_A(wb_rd_A),
    .wb_data_A(wb_data_A),

    .wb_en_B(wb_en_B),
    .wb_rd_B(wb_rd_B),
    .wb_data_B(wb_data_B),
    .wb_age_A(wb_age_A),
    .wb_age_B(wb_age_B),

    .ID_EX_IR_A(ID_EX_IR_A),
    .ID_EX_PC_A(ID_EX_PC_A),
    .ID_EX_X0_A(ID_EX_X0_A),
    .ID_EX_X1_A(ID_EX_X1_A),
    .ID_EX_IMM_A(ID_EX_IMM_A),
    .ID_EX_TYPE_A(ID_EX_TYPE_A),
    .ID_EX_AGE_A(ID_EX_AGE_A),

    .ID_EX_IR_B(ID_EX_IR_B),
    .ID_EX_PC_B(ID_EX_PC_B),
    .ID_EX_X0_B(ID_EX_X0_B),
    .ID_EX_X1_B(ID_EX_X1_B),
    .ID_EX_IMM_B(ID_EX_IMM_B),
    .ID_EX_TYPE_B(ID_EX_TYPE_B),
    .ID_EX_AGE_B(ID_EX_AGE_B),
    .type0(type0),
    .type1(type1)

);

//====================================================
// EXECUTE A
//====================================================

EX_A_STAGE EX_A(

    .clk(clk1),
    .reset(reset),

    .stall_EX(stall_EX),

    .ID_EX_IR_A(ID_EX_IR_A),
    .ID_EX_PC_A(ID_EX_PC_A),
    .ID_EX_X0_A(ID_EX_X0_A),
    .ID_EX_X1_A(ID_EX_X1_A),
    .ID_EX_IMM_A(ID_EX_IMM_A),
    .ID_EX_TYPE_A(ID_EX_TYPE_A),
    .ID_EX_AGE_A(ID_EX_AGE_A),

    .EX_MEM_IR_A(EX_MEM_IR_A),
    .EX_MEM_ALUout_A(EX_MEM_ALUout_A),
    .EX_MEM_TYPE_A(EX_MEM_TYPE_A),
    .EX_MEM_AGE_A(EX_MEM_AGE_A),

    .branched(branched),
    .next_pc(next_pc),
    .branch_taken(branch_taken)
);

//====================================================
// EXECUTE B
//====================================================

EX_B_STAGE EX_B(

    .clk(clk1),
    .reset(reset),
    .branched(branch_taken),
    .stall_EX(stall_EX),

    .ID_EX_IR_B(ID_EX_IR_B),
    .ID_EX_AGE_B(ID_EX_AGE_B),
    .ID_EX_X0_B(ID_EX_X0_B),
    .ID_EX_X1_B(ID_EX_X1_B),
    .ID_EX_IMM_B(ID_EX_IMM_B),
    .ID_EX_TYPE_B(ID_EX_TYPE_B),
    .ID_EX_PC_B(ID_EX_PC_B),
    .EX_MEM_IR_B(EX_MEM_IR_B),
    .EX_MEM_ALUout_B(EX_MEM_ALUout_B),
    .EX_MEM_X1_B(EX_MEM_X1_B),
    .EX_MEM_TYPE_B(EX_MEM_TYPE_B),
    .EX_MEM_AGE_B(EX_MEM_AGE_B)

);

//====================================================
// MEMORY A
//====================================================

MEM_A MEM_STAGE_A(

    .clk(clk2),
    .reset(reset),

    .EX_MEM_IR_A(EX_MEM_IR_A),
    .EX_MEM_ALUout_A(EX_MEM_ALUout_A),
    .EX_MEM_TYPE_A(EX_MEM_TYPE_A),
    .EX_MEM_AGE_A(EX_MEM_AGE_A),

    .MEM_WB_IR_A(MEM_WB_IR_A),
    .MEM_WB_ALUout_A(MEM_WB_ALUout_A),
    .MEM_WB_TYPE_A(MEM_WB_TYPE_A),
    .MEM_WB_AGE_A(MEM_WB_AGE_A)

);

//====================================================
// MEMORY B
//====================================================

MEM_B MEM_STAGE_B(

    .clk(clk2),
    .reset(reset),

    .branched(branched),

    .EX_MEM_IR_B(EX_MEM_IR_B),
    .EX_MEM_ALUout_B(EX_MEM_ALUout_B),
    .EX_MEM_X1_B(EX_MEM_X1_B),
    .EX_MEM_TYPE_B(EX_MEM_TYPE_B),
    .EX_MEM_AGE_B(EX_MEM_AGE_B),

    .MEM_WB_IR_B(MEM_WB_IR_B),
    .MEM_WB_ALUout_B(MEM_WB_ALUout_B),
    .MEM_WB_LMD_B(MEM_WB_LMD_B),
    .MEM_WB_TYPE_B(MEM_WB_TYPE_B),
    .MEM_WB_AGE_B(MEM_WB_AGE_B)

);

//====================================================
// WRITEBACK A
//====================================================

WB_A WB_STAGE_A(

    .clk(clk1),
    .reset(reset),

    .MEM_WB_IR_A(MEM_WB_IR_A),
    .MEM_WB_ALUout_A(MEM_WB_ALUout_A),
    .MEM_WB_TYPE_A(MEM_WB_TYPE_A),
    .MEM_WB_AGE_A(MEM_WB_AGE_A),

    .write_en(wb_en_A),
    .rd(wb_rd_A),
    .write_data(wb_data_A),
    .age(wb_age_A)

);

//====================================================
// WRITEBACK B
//====================================================

WB_B WB_STAGE_B(

    .clk(clk1),
    .reset(reset),

    .MEM_WB_IR_B(MEM_WB_IR_B),
    .MEM_WB_ALUout_B(MEM_WB_ALUout_B),
    .MEM_WB_LMD_B(MEM_WB_LMD_B),
    .MEM_WB_TYPE_B(MEM_WB_TYPE_B),
    .MEM_WB_AGE_B(MEM_WB_AGE_B),

    .write_en(wb_en_B),
    .rd(wb_rd_B),
    .write_data(wb_data_B),
    .age(wb_age_B)

);

//====================================================
// HAZARD UNIT
//====================================================

DATA_hazard_handler HAZARD(
    .IF_ID_IR_0(IF_ID_IR_0),
    .IF_ID_IR_1(IF_ID_IR_1),

    .IF_ID_TYPE_0(type0),
    .IF_ID_TYPE_1(type1),

//    .ID_EX_IR_A(ID_EX_IR_A),
//    .ID_EX_IR_B(ID_EX_IR_B),

//    .ID_EX_TYPE_A(ID_EX_TYPE_A),
//    .ID_EX_TYPE_B(ID_EX_TYPE_B),

    .EX_MEM_IR_A(EX_MEM_IR_A),
    .EX_MEM_IR_B(EX_MEM_IR_B),

    .EX_MEM_TYPE_A(EX_MEM_TYPE_A),
    .EX_MEM_TYPE_B(EX_MEM_TYPE_B),

//    .MEM_WB_IR_A(MEM_WB_IR_A),
//    .MEM_WB_IR_B(MEM_WB_IR_B),

//    .MEM_WB_TYPE_A(MEM_WB_TYPE_A),
//    .MEM_WB_TYPE_B(MEM_WB_TYPE_B),

//    .ID_ID_hazard(ID_ID_hazard),
//    .ID_EX_hazard(ID_EX_hazard),
//    .ID_MEM_hazard(ID_MEM_hazard),
//    .ID_WB_hazard(ID_WB_hazard),

    .hazard_ID_stall(hazard_ID_stall),
//    .hazard_ID_unstall(hazard_ID_unstall),
    .hazard_stall(hazard_stall)

);

endmodule