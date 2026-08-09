module ALU_B(
input  [31:0] A,
input  [31:0] B,
input  [31:0] IMM,
input  [31:0] IR,
input  [31:0] PC,

output reg [31:0] ALUout
);

//====================================================
// RV32I MAIN OPCODES
//====================================================

parameter
        LUI      = 7'b0110111,
        AUIPC    = 7'b0010111,
        LOAD     = 7'b0000011,
        STORE    = 7'b0100011,
        OP_IMM   = 7'b0010011,
        OP       = 7'b0110011,
//====================================================
// FUNCT3 VALUES
//====================================================

    F3_ADD_SUB  = 3'b000,
    F3_SLL      = 3'b001,
    F3_SLT      = 3'b010,
    F3_SLTU     = 3'b011,
    F3_XOR      = 3'b100,
    F3_SRL_SRA  = 3'b101,
    F3_OR       = 3'b110,
    F3_AND      = 3'b111,

//====================================================
// LOAD
//====================================================

    F3_LB       = 3'b000,
    F3_LH       = 3'b001,
    F3_LW       = 3'b010,
    F3_LBU      = 3'b100,
    F3_LHU      = 3'b101,

//====================================================
// STORE
//====================================================

    F3_SB       = 3'b000,
    F3_SH       = 3'b001,
    F3_SW       = 3'b010,

//====================================================
// FUNCT7 VALUES
//====================================================

    F7_ADD      = 7'b0000000,
    F7_SUB      = 7'b0100000,
    F7_SRL      = 7'b0000000,
    F7_SRA      = 7'b0100000;

//====================================================
// INTERNAL WIRES
//====================================================

wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode = IR[6:0];
assign funct3 = IR[14:12];
assign funct7 = IR[31:25];

//====================================================
// MAIN ALU
//====================================================

always @(*)
begin

case(opcode)

//====================================================
// LOAD ADDRESS GENERATION
//====================================================
LUI:
begin
    ALUout = IMM;
end

AUIPC:
begin
    ALUout = PC + IMM;
end 

LOAD:
begin

    case(funct3)

    F3_LB  : ALUout = A + IMM;
    F3_LH  : ALUout = A + IMM;
    F3_LW  : ALUout = A + IMM;
    F3_LBU : ALUout = A + IMM;
    F3_LHU : ALUout = A + IMM;

    default:
        ALUout = 32'd0;

    endcase

end

//====================================================
// STORE ADDRESS GENERATION
//====================================================

STORE:
begin

    case(funct3)

    F3_SB:
        ALUout = A + IMM;

    F3_SH:
        ALUout = A + IMM;

    F3_SW:
        ALUout = A + IMM;

    default:
        ALUout = 32'd0;

    endcase

end

//====================================================
// OP IMM
//====================================================

OP_IMM:
begin

    case(funct3)

    F3_ADD_SUB:
        ALUout = A + IMM;

    F3_SLL:
        ALUout = A << IR[24:20];

    F3_SLT:
        ALUout = ($signed(A) < $signed(IMM));

    F3_SLTU:
        ALUout = (A < IMM);

    F3_XOR:
        ALUout = A ^ IMM;

    F3_OR:
        ALUout = A | IMM;

    F3_AND:
        ALUout = A & IMM;

    F3_SRL_SRA:
    begin

        case(funct7)

        F7_SRL:
            ALUout = A >> IR[24:20];

        F7_SRA:
            ALUout = $signed(A) >>> IR[24:20];

        default:
            ALUout = 32'd0;

        endcase

    end

    default:
        ALUout = 32'd0;

    endcase

end

//====================================================
// R TYPE
//====================================================

OP:
begin

    case(funct3)

    F3_ADD_SUB:
    begin

        case(funct7)

        F7_ADD:
            ALUout = A + B;

        F7_SUB:
            ALUout = A - B;

        default:
            ALUout = 32'd0;

        endcase

    end

    F3_SLL:
        ALUout = A << B[4:0];

    F3_SLT:
        ALUout = ($signed(A) < $signed(B));

    F3_SLTU:
        ALUout = (A < B);

    F3_XOR:
        ALUout = A ^ B;

    F3_OR:
        ALUout = A | B;

    F3_AND:
        ALUout = A & B;

    F3_SRL_SRA:
    begin

        case(funct7)

        F7_SRL:
            ALUout = A >> B[4:0];

        F7_SRA:
            ALUout = $signed(A) >>> B[4:0];

        default:
            ALUout = 32'd0;

        endcase

    end

    default:
        ALUout = 32'd0;

    endcase

end

default:
    ALUout = 32'd0;

endcase

end

endmodule