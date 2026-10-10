module DATA_hazard_handler(

input [31:0] IF_ID_IR_0,
input [31:0] IF_ID_IR_1,

input [2:0]  IF_ID_TYPE_0,
input [2:0]  IF_ID_TYPE_1,

input [31:0] EX_MEM_IR_A,
input [31:0] EX_MEM_IR_B,

input [2:0]  EX_MEM_TYPE_A,
input [2:0]  EX_MEM_TYPE_B,  
output wire hazard_ID_stall,
output wire hazard_stall
);
reg ID_ID_hazard;
reg ID_MEM_hazard;

// INTERNAL TYPES
 

parameter
    TYPE_R   = 3'b000,
    TYPE_I   = 3'b001,
    TYPE_S   = 3'b010,
    TYPE_B   = 3'b011,
    TYPE_U   = 3'b100,
    TYPE_J   = 3'b101,
    TYPE_NOP = 3'b111;

 
// OPCODES
 

parameter
    LOAD     = 7'b0000011,
    STORE    = 7'b0100011,
    OP_IMM   = 7'b0010011,
    OP       = 7'b0110011,
    BRANCH   = 7'b1100011,
    JALR     = 7'b1100111;

 
// RD FUNCTION
 

function automatic [4:0] rd;

input [31:0] ir;
input [2:0]  type;

begin

case(type)

TYPE_R,
TYPE_I,
TYPE_U,
TYPE_J:
    rd = ir[11:7];

default:
    rd = 5'd0;

endcase

end

endfunction

 
// RS1 FUNCTION
 

function automatic [4:0] rs1;

input [31:0] ir;

begin

case(ir[6:0])

OP,
OP_IMM,
LOAD,
STORE,
BRANCH,
JALR:
    rs1 = ir[19:15];

default:
    rs1 = 5'd0;

endcase

end

endfunction

 
// RS2 FUNCTION
 

function automatic [4:0] rs2;

input [31:0] ir;
input [2:0]  type;

begin

case(ir[6:0])

OP,
STORE,
BRANCH:
    rs2 = ir[24:20];

default:
    rs2 = 5'd0;

endcase

end

endfunction

 
// ID-ID HAZARD
 

task automatic check_ID_ID_hazard;

input [31:0] prod_ir;
input [2:0]  prod_type;

input [31:0] cons_ir;
input [2:0]  cons_type;

begin

if(rd(prod_ir,prod_type) != 5'd0)
begin

    if(rd(prod_ir,prod_type) == rs1(cons_ir))
        ID_ID_hazard = 1'b1;

    else if(rd(prod_ir,prod_type) == rs2(cons_ir,cons_type))
        ID_ID_hazard = 1'b1;
 
end

end

endtask

 
task automatic check_ID_MEM_hazard;

input [31:0] prod_ir;
input [2:0]  prod_type;

input [31:0] cons_ir;
input [2:0]  cons_type;

begin

if(rd(prod_ir,prod_type) != 5'd0)
begin

    if(rd(prod_ir,prod_type) == rs1(cons_ir))
        ID_MEM_hazard = 1'b1;

    else if(rd(prod_ir,prod_type) == rs2(cons_ir,cons_type))
        ID_MEM_hazard = 1'b1;

end

end

endtask

// MAIN HAZARD LOGIC
 

always @(*)
begin

ID_ID_hazard  = 1'b0;
ID_MEM_hazard = 1'b0;

check_ID_ID_hazard(
    IF_ID_IR_0,
    IF_ID_TYPE_0,
    IF_ID_IR_1,
    IF_ID_TYPE_1
);

check_ID_MEM_hazard(
    EX_MEM_IR_A,
    EX_MEM_TYPE_A,
    IF_ID_IR_0,
    IF_ID_TYPE_0
);

check_ID_MEM_hazard(
    EX_MEM_IR_B,
    EX_MEM_TYPE_B,
    IF_ID_IR_0,
    IF_ID_TYPE_0
);

check_ID_MEM_hazard(
    EX_MEM_IR_A,
    EX_MEM_TYPE_A,
    IF_ID_IR_1,
    IF_ID_TYPE_1
);

check_ID_MEM_hazard(
    EX_MEM_IR_B,
    EX_MEM_TYPE_B,
    IF_ID_IR_1,
    IF_ID_TYPE_1
);

end
assign hazard_ID_stall = ID_ID_hazard & ~hazard_stall;
assign hazard_stall = ID_MEM_hazard;

endmodule