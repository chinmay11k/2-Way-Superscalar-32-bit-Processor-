module decode_issue_stage(

    input wire clk1,
    input wire clk2,
    input wire reset,

    input wire stall_ID,
    input wire hazard_ID_stall,
    input wire branched,
    output reg stall_II,

    input wire [31:0] IF_ID_IR_0,
    input wire [31:0] IF_ID_IR_1,

    input wire [31:0] IF_ID_PC_0,
    input wire [31:0] IF_ID_PC_1,

    // WB pipe A
    input wire wb_en_A,
    input wire [4:0] wb_rd_A,
    input wire [31:0] wb_data_A,
    input wire wb_age_A,

    // WB pipe B
    input wire wb_en_B,
    input wire [4:0] wb_rd_B,
    input wire [31:0] wb_data_B,
    input wire wb_age_B,

    // pipe A out
    output reg [31:0] ID_EX_IR_A,
    output reg [31:0] ID_EX_PC_A,
    output reg [31:0] ID_EX_X0_A,
    output reg [31:0] ID_EX_X1_A,
    output reg [31:0] ID_EX_IMM_A,
    output reg [2:0] ID_EX_TYPE_A,

    // pipe B out
    output reg [31:0] ID_EX_IR_B,
    output reg [31:0] ID_EX_PC_B,
    output reg [31:0] ID_EX_X0_B,
    output reg [31:0] ID_EX_X1_B,
    output reg [31:0] ID_EX_IMM_B,
    output reg [2:0] ID_EX_TYPE_B,
    output reg ID_EX_AGE_A,
    output reg ID_EX_AGE_B,
    output reg [2:0] type0,
    output reg [2:0] type1

);

parameter TYPE_R   = 3'b000,
          TYPE_I   = 3'b001,
          TYPE_S   = 3'b010,
          TYPE_B   = 3'b011,
          TYPE_U   = 3'b100,
          TYPE_J   = 3'b101,
          TYPE_NOP = 3'b111;

parameter FU_ALU    = 2'b00,
          FU_MEM    = 2'b01,
          FU_BRANCH = 2'b10,
          FU_NONE   = 2'b11;

parameter LUI      = 7'b0110111,
          AUIPC    = 7'b0010111,
          JAL      = 7'b1101111,
          JALR     = 7'b1100111,
          BRANCH   = 7'b1100011,
          LOAD     = 7'b0000011,
          STORE    = 7'b0100011,
          OP_IMM   = 7'b0010011,
          OP       = 7'b0110011,
          MISC_MEM = 7'b0001111,
          SYSTEM   = 7'b1110011;

parameter NOP_INST = 32'h00000013;

wire [4:0] rs1_0 = IF_ID_IR_0[19:15];
wire [4:0] rs2_0 = IF_ID_IR_0[24:20];

wire [4:0] rs1_1 = IF_ID_IR_1[19:15];
wire [4:0] rs2_1 = IF_ID_IR_1[24:20];

wire [31:0] rs1_data_0;
wire [31:0] rs2_data_0;

wire [31:0] rs1_data_1;
wire [31:0] rs2_data_1;

//reg [2:0] type0;
//reg [2:0] type1;

reg [1:0] fu0;
reg [1:0] fu1;


// register file

reg_file_module RF(

    .clk(clk1),
    .reset(reset),

    .rs1_A(rs1_0),
    .rs2_A(rs2_0),

    .rs1_B(rs1_1),
    .rs2_B(rs2_1),

    .rs1_data_A(rs1_data_0),
    .rs2_data_A(rs2_data_0),

    .rs1_data_B(rs1_data_1),
    .rs2_data_B(rs2_data_1),

    .write_en_A(wb_en_A),
    .rd_A(wb_rd_A),
    .write_data_A(wb_data_A),
    .age_A(wb_age_A),

    .write_en_B(wb_en_B),
    .rd_B(wb_rd_B),
    .write_data_B(wb_data_B),
    .age_B(wb_age_B)

);


// decode instruction type

function [2:0] decode_type;

    input [31:0] inst;

    begin

        case(inst[6:0])

            OP       : decode_type = TYPE_R;

            OP_IMM   : decode_type = TYPE_I;
            LOAD     : decode_type = TYPE_I;
            JALR     : decode_type = TYPE_I;
            SYSTEM   : decode_type = TYPE_I;

            STORE    : decode_type = TYPE_S;

            BRANCH   : decode_type = TYPE_B;

            LUI      : decode_type = TYPE_U;
            AUIPC    : decode_type = TYPE_U;

            JAL      : decode_type = TYPE_J;

            default  : decode_type = TYPE_NOP;

        endcase

    end

endfunction


// classify FU type

function [1:0] decode_fu;

    input [31:0] inst;

    begin

        case(inst[6:0])

            OP      : decode_fu = FU_ALU;
            OP_IMM  : decode_fu = FU_ALU;

            LUI     : decode_fu = FU_ALU;
            AUIPC   : decode_fu = FU_ALU;

            LOAD    : decode_fu = FU_MEM;
            STORE   : decode_fu = FU_MEM;

            BRANCH  : decode_fu = FU_BRANCH;
            JAL     : decode_fu = FU_BRANCH;
            JALR    : decode_fu = FU_BRANCH;

            default : decode_fu = FU_NONE;

        endcase

    end

endfunction

function [31:0] generate_imm;

    input [31:0] inst;
    input [2:0] inst_type;

    begin

        case(inst_type)

            //---------------------------------
            // R
            //---------------------------------

            TYPE_R:
                generate_imm = 32'd0;

            //---------------------------------
            // I
            //---------------------------------

            TYPE_I:
                generate_imm =
                {{20{inst[31]}},
                  inst[31:20]};

            //---------------------------------
            // S
            //---------------------------------

            TYPE_S:
                generate_imm =
                {{20{inst[31]}},
                  inst[31:25],
                  inst[11:7]};

            //---------------------------------
            // B
            //---------------------------------

            TYPE_B:
                generate_imm =
                {{19{inst[31]}},
                  inst[31],
                  inst[7],
                  inst[30:25],
                  inst[11:8],
                  1'b0};

            //---------------------------------
            // U
            //---------------------------------

            TYPE_U:
                generate_imm =
                {inst[31:12],
                 12'b0};

            //---------------------------------
            // J
            //---------------------------------

            TYPE_J:
                generate_imm =
                {{11{inst[31]}},
                  inst[31],
                  inst[19:12],
                  inst[20],
                  inst[30:21],
                  1'b0};

            default:
                generate_imm = 32'd0;

        endcase

    end

endfunction


always @(*)
begin

    type0 = decode_type(IF_ID_IR_0);
    type1 = decode_type(IF_ID_IR_1);

    fu0 = decode_fu(IF_ID_IR_0);
    fu1 = decode_fu(IF_ID_IR_1);
end


// assign pipe A

task issue_A;

    input [31:0] inst;
    input [31:0] pc;
    input [31:0] x0;
    input [31:0] x1;
    input [2:0] inst_type;
    input age;
    begin

        ID_EX_IR_A   <= inst;
        ID_EX_PC_A   <= pc;
        ID_EX_X0_A   <= x0;
        ID_EX_X1_A   <= x1;
        ID_EX_IMM_A  <= generate_imm(inst, inst_type);
        ID_EX_TYPE_A <= inst_type;
        ID_EX_AGE_A <= age;
    end

endtask


// assign pipe B

task issue_B;

    input [31:0] inst;
    input [31:0] pc;
    input [31:0] x0;
    input [31:0] x1;
    input [2:0] inst_type;
    input age;
    begin

        ID_EX_IR_B   <= inst;
        ID_EX_PC_B   <= pc;
        ID_EX_X0_B   <= x0;
        ID_EX_X1_B   <= x1;
//        ID_EX_IMM_B  <= {{20{inst[31]}},inst[31:20]};
        ID_EX_IMM_B <= generate_imm(inst, inst_type);
        ID_EX_TYPE_B <= inst_type;
        ID_EX_AGE_B <= age;
    end

endtask


// nop pipe A

task nop_A;
begin

    ID_EX_IR_A   <= NOP_INST;
    ID_EX_PC_A   <= 32'd0;
    ID_EX_X0_A   <= 32'd0;
    ID_EX_X1_A   <= 32'd0;
    ID_EX_IMM_A  <= 32'd0;
    ID_EX_TYPE_A <= TYPE_NOP;
    ID_EX_AGE_A <= 1'b0;
end
endtask


// nop pipe B

task nop_B;
begin

    ID_EX_IR_B   <= NOP_INST;
    ID_EX_PC_B   <= 32'd0;
    ID_EX_X0_B   <= 32'd0;
    ID_EX_X1_B   <= 32'd0;
    ID_EX_IMM_B  <= 32'd0;
    ID_EX_TYPE_B <= TYPE_NOP;
    ID_EX_AGE_B <= 1'b0;
end
endtask


always @(posedge clk2)
begin

    if(reset)
    begin

        nop_A();
        nop_B();

        stall_II <= 1'b0;

    end

    // flush after branch

    else if(branched)
    begin

        nop_A();
        nop_B();
        stall_II <= 1'b0;

    end

    // replay second instruction after structural stall

    else if(stall_II)
    begin

        stall_II <= 1'b0;

        case(fu1)

            FU_MEM:
            begin
                nop_A();
                issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
            end

            FU_BRANCH:
            begin
                issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                nop_B();
            end

            default:
            begin
                nop_A();
                nop_B();
            end

        endcase

    end

    else if(stall_ID)
    begin

        // During an ID stall hold both issue slots (do not issue)
        nop_A();
        nop_B();

    end
 
    else if(!stall_ID)
    begin

        // If a hazard-driven stall request exists while ID is not stalled,
        // issue only the first instruction and hold the second.
        if (hazard_ID_stall)
        begin
            case(fu0)

                FU_ALU,
                FU_BRANCH:
                begin
                    issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    nop_B();
                end

                FU_MEM:
                begin
                    nop_A();
                    issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                end

                default:
                begin
                    nop_A();
                    nop_B();
                end

            endcase
        end
        else
        begin

        case(fu0)

            // first inst ALU

            FU_ALU:
            begin

                case(fu1)

                    // dual ALU

                    FU_ALU:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                    end

                    // ALU + MEM

                    FU_MEM:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                    end

                    // ALU + BRANCH

                    FU_BRANCH:
                    begin
                        issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                        issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    end

                    default:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        nop_B();
                    end

                endcase

            end


            // first inst MEM

            FU_MEM:
            begin

                case(fu1)

                    // MEM + ALU

                    FU_ALU:
                    begin
                        issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                        issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    end

                    // MEM + MEM -> structural stall

                    FU_MEM:
                    begin
                        stall_II <= 1'b1;

                        nop_A();

                        issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    end

                    // MEM + BRANCH

                    FU_BRANCH:
                    begin
                        issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                        issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    end

                    default:
                    begin
                        nop_A();

                        issue_B(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                    end

                endcase

            end


            // first inst BRANCH

            FU_BRANCH:
            begin

                case(fu1)

                    // BRANCH + ALU

                    FU_ALU:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                    end

                    // BRANCH + MEM

                    FU_MEM:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                    end

                    // BRANCH + BRANCH -> stall

                    FU_BRANCH:
                    begin
                        stall_II <= 1'b1;

                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);

                        nop_B();
                    end

                    default:
                    begin
                        issue_A(IF_ID_IR_0,IF_ID_PC_0,rs1_data_0,rs2_data_0,type0,1'b0);
                        nop_B();
                    end

                endcase

            end


            default:
            begin

                case(fu1)

                    FU_ALU:
                    begin
                        issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                        nop_B();
                    end

                    FU_MEM:
                    begin
                        nop_A();
                        issue_B(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                    end

                    FU_BRANCH:
                    begin
                        issue_A(IF_ID_IR_1,IF_ID_PC_1,rs1_data_1,rs2_data_1,type1,1'b1);
                        nop_B();
                    end

                    default:
                    begin
                        nop_A();
                        nop_B();
                    end

                endcase

            end

        endcase

    end

end
end
endmodule