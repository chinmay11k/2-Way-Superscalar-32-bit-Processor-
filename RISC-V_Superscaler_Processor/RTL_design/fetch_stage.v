module fetch_stage(
    input wire clk,
    input wire reset,
    input wire stall_IF,
    input wire hazard_ID_stall,
    input wire branched,
    input wire [31:0] branch_target,
    output reg [31:0] IF_ID_IR_0,
    output reg [31:0] IF_ID_IR_1,
    output reg [31:0] IF_ID_PC_0,
    output reg [31:0] IF_ID_PC_1
);
reg [31:0] PC;

parameter NOP_INST = 32'h00000013;

wire [31:0] inst0;
wire [31:0] inst1;

// instruction memory instantiation
wire [31:0] fetch_pc;

assign fetch_pc = (branched) ? branch_target :(stall_IF|hazard_ID_stall)?PC: PC;

inst_mem IMEM(
    .addr0(fetch_pc),
    .addr1(fetch_pc + 32'd4),
    .inst0(inst0),
    .inst1(inst1)
);

always @(posedge clk)
begin

    if(reset)
    begin

        PC <= 32'd0;
        IF_ID_IR_0 <= NOP_INST;
        IF_ID_IR_1 <= NOP_INST;
        IF_ID_PC_0 <= 32'd0;
        IF_ID_PC_1 <= 32'd4;
    end
    else if(branched)
    begin

        // Branch: highest priority. Flush and redirect to branch target.
        PC <= branch_target + 32'd8;
        IF_ID_PC_0 <= branch_target;
        IF_ID_PC_1 <= branch_target + 32'd4;
        IF_ID_IR_0 <= inst0;
        IF_ID_IR_1 <= inst1;

    end
    else if(stall_IF)
    begin

        // stall_IF: hold all outputs and PC, do not advance

    end
    else if(hazard_ID_stall)
    begin

        // ID-ID hazard: present inst1 in slot1 and NOP in slot0,
        // advance PC by 4 so inst1 becomes inst0 next cycle.
        IF_ID_IR_0 <= NOP_INST;
//        IF_ID_IR_1 <= inst1;

//        IF_ID_PC_0 <= PC;
//        IF_ID_PC_1 <= PC + 32'd4;

//        // Advance PC by 4 so next cycle fetches inst1 as inst0
//        PC <= PC + 32'd4;
    end
    else
    begin

        // normal case: issue both instructions, advance PC by 8
        IF_ID_IR_0 <= inst0;
        IF_ID_IR_1 <= inst1;

        IF_ID_PC_0 <= PC;
        IF_ID_PC_1 <= PC + 32'd4;
        PC <= PC + 32'd8;

    end

end

endmodule