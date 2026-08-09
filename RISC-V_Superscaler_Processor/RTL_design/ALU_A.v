module ALU_A(
input  [31:0] A,
input  [31:0] B,
input  [31:0] IMM,
input  [31:0] PC,
input  [31:0] IR,
output reg [31:0] ALUout,
output reg        branch_taken,
output reg [31:0] next_pc
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
    MISC_MEM = 7'b0001111,
    SYSTEM   = 7'b1110011,

 
// FUNCT3 VALUES
 

    F3_ADD_SUB  = 3'b000,
    F3_SLL      = 3'b001,
    F3_SLT      = 3'b010,
    F3_SLTU     = 3'b011,
    F3_XOR      = 3'b100,
    F3_SRL_SRA  = 3'b101,
    F3_OR       = 3'b110,
    F3_AND      = 3'b111,

    F3_BEQ      = 3'b000,
    F3_BNE      = 3'b001,
    F3_BLT      = 3'b100,
    F3_BGE      = 3'b101,
    F3_BLTU     = 3'b110,
    F3_BGEU     = 3'b111,

 
// FUNCT7 VALUES
 

    F7_ADD      = 7'b0000000,
    F7_SUB      = 7'b0100000,
    F7_SRL      = 7'b0000000,
    F7_SRA      = 7'b0100000;

 
// INTERNAL WIRES
 

wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode = IR[6:0];
assign funct3 = IR[14:12];
assign funct7 = IR[31:25];

 
// MAIN ALU
 

always @(*)
begin
    // default assignments to avoid latches and X values
    ALUout = 32'd0;
    branch_taken = 1'b0;
    next_pc = PC + 32'd4;
case(opcode)
// R TYPE
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
        default :            ALUout = A + B;

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

    F3_OR:
        ALUout = A | B;

    F3_AND:
        ALUout = A & B;

    default:
        ALUout = 32'd0;

    endcase

end

 
// I TYPE
 

OP_IMM:
begin

    case(funct3)

    F3_ADD_SUB:
        ALUout = A + IMM;

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

    F3_SLL:
        ALUout = A << IR[24:20];

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

 
// U TYPE
 

LUI:
    ALUout = IMM;

AUIPC:
    ALUout = PC + IMM;

 
// BRANCH
 

BRANCH:
begin

    case(funct3)

    F3_BEQ:
        branch_taken = (A == B);

    F3_BNE:
        branch_taken = (A != B);

    F3_BLT:
        branch_taken = ($signed(A) < $signed(B));

    F3_BGE:
        branch_taken = ($signed(A) >= $signed(B));

    F3_BLTU:
        branch_taken = (A < B);

    F3_BGEU:
        branch_taken = (A >= B);
        default :            branch_taken =0;

    endcase

    if(branch_taken)
        next_pc = PC +IMM;
    end

 
// JUMPS
 

JAL:
begin

    ALUout       = PC + 32'd4;
    branch_taken = 1'b1;
//    next_pc      = PC +IMM;
    next_pc      = PC + IMM;

end

JALR:
begin

    ALUout       = PC + 32'd4;
    branch_taken = 1'b1;
    next_pc      = (A +IMM) & 32'hfffffffe;

end

default:
begin

    ALUout       = 32'd0;
    branch_taken = 1'b0;
    next_pc      = PC + 32'd4;

end

endcase

end

endmodule