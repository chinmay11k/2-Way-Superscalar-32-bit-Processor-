module DATA_hazard_handler(

// IF/ID STAGE
input [31:0] IF_ID_IR_0,
input [31:0] IF_ID_IR_1,

input [2:0]  IF_ID_TYPE_0,
input [2:0]  IF_ID_TYPE_1,

//// ID/EX STAGE
// input [31:0] ID_EX_IR_A,
//input [31:0] ID_EX_IR_B,

//input [2:0]  ID_EX_TYPE_A,
//input [2:0]  ID_EX_TYPE_B,

 
// EX/MEM STAGE
 

input [31:0] EX_MEM_IR_A,
input [31:0] EX_MEM_IR_B,

input [2:0]  EX_MEM_TYPE_A,
input [2:0]  EX_MEM_TYPE_B,

 
//// MEM/WB STAGE
 

//input [31:0] MEM_WB_IR_A,
//input [31:0] MEM_WB_IR_B,

//input [2:0]  MEM_WB_TYPE_A,
//input [2:0]  MEM_WB_TYPE_B,

 
// OUTPUTS
 

//output reg ID_ID_hazard,
////output reg ID_EX_hazard,
//output reg ID_MEM_hazard,
//output reg ID_WB_hazard,
  
output wire hazard_ID_stall,
output wire hazard_stall
);
reg ID_ID_hazard;
//reg ID_EX_hazard;
reg ID_MEM_hazard;
//reg ID_WB_hazard;

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

 
//// ID-EX HAZARD
 

//task automatic check_ID_EX_hazard;

//input [31:0] prod_ir;
//input [2:0]  prod_type;

//input [31:0] cons_ir;
//input [2:0]  cons_type;

//begin

//if(rd(prod_ir,prod_type) != 5'd0)
//begin

//    if(rd(prod_ir,prod_type) == rs1(cons_ir))
//        ID_EX_hazard = 1'b1;

//    else if(rd(prod_ir,prod_type) == rs2(cons_ir,cons_type))
//        ID_EX_hazard = 1'b1;

//end

//end

//endtask

 
// ID-MEM HAZARD
 

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

 
// ID-WB HAZARD
 

//task automatic check_ID_WB_hazard;

//input [31:0] prod_ir;
//input [2:0]  prod_type;

//input [31:0] cons_ir;
//input [2:0]  cons_type;

//begin

//if(rd(prod_ir,prod_type) != 5'd0)
//begin

//    if(rd(prod_ir,prod_type) == rs1(cons_ir))
//        ID_WB_hazard = 1'b1;

//    else if(rd(prod_ir,prod_type) == rs2(cons_ir,cons_type))
//        ID_WB_hazard = 1'b1;

//end

//end

//endtask

 
// MAIN HAZARD LOGIC
 

always @(*)
begin

ID_ID_hazard  = 1'b0;
//ID_EX_hazard  = 1'b0;
ID_MEM_hazard = 1'b0;
//ID_WB_hazard  = 1'b0;

//===========================================
// IF-ID INTERNAL HAZARD
//===========================================

check_ID_ID_hazard(
    IF_ID_IR_0,
    IF_ID_TYPE_0,
    IF_ID_IR_1,
    IF_ID_TYPE_1
);

//===========================================
// ID-EX HAZARD
//===========================================

//check_ID_EX_hazard(
//    ID_EX_IR_A,
//    ID_EX_TYPE_A,
//    IF_ID_IR_0,
//    IF_ID_TYPE_0
//);

//check_ID_EX_hazard(
//    ID_EX_IR_B,
//    ID_EX_TYPE_B,
//    IF_ID_IR_0,
//    IF_ID_TYPE_0
//);

//check_ID_EX_hazard(
//    ID_EX_IR_A,
//    ID_EX_TYPE_A,
//    IF_ID_IR_1,
//    IF_ID_TYPE_1
//);

//check_ID_EX_hazard(
//    ID_EX_IR_B,
//    ID_EX_TYPE_B,
//    IF_ID_IR_1,
//    IF_ID_TYPE_1
//);

//===========================================
// ID-MEM HAZARD
//===========================================

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

//===========================================
// ID-WB HAZARD
//===========================================

//check_ID_WB_hazard(
//    MEM_WB_IR_A,
//    MEM_WB_TYPE_A,
//    IF_ID_IR_0,
//    IF_ID_TYPE_0
//);

//check_ID_WB_hazard(
//    MEM_WB_IR_B,
//    MEM_WB_TYPE_B,
//    IF_ID_IR_0,
//    IF_ID_TYPE_0
//);

//check_ID_WB_hazard(
//    MEM_WB_IR_A,
//    MEM_WB_TYPE_A,
//    IF_ID_IR_1,
//    IF_ID_TYPE_1
//);

//check_ID_WB_hazard(
//    MEM_WB_IR_B,
//    MEM_WB_TYPE_B,
//    IF_ID_IR_1,
//    IF_ID_TYPE_1
//);

end

 
//// STALL LOGIC
//// hazard_ID_stall is asserted for one cycle when there is an ID-ID hazard
//// and no higher-priority later-stage RAW hazard.

//always @(posedge clk)
//begin
//    if (reset)
//    begin
//        id_id_hold <= 1'b0;
//    end
//    else
//    begin
//        // Hold one cycle when an ID-ID hazard is detected.
//        if (ID_ID_hazard && !id_id_hold)
//        begin
//            id_id_hold <= 1'b1;
//        end
//        else
//        begin
//            id_id_hold <= 1'b0;
//        end
//    end
//end

assign hazard_ID_stall = ID_ID_hazard & ~hazard_stall;
assign hazard_stall = ID_MEM_hazard;

endmodule