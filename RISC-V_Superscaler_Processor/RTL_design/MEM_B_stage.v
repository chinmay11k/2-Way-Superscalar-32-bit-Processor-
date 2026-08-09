module MEM_B(
input clk,
input reset,
input branched,

input  [31:0] EX_MEM_IR_B,
input  [31:0] EX_MEM_ALUout_B,
input  [31:0] EX_MEM_X1_B,
input  [2:0]  EX_MEM_TYPE_B,
input         EX_MEM_AGE_B,

output reg [31:0] MEM_WB_IR_B,
output reg [31:0] MEM_WB_ALUout_B,
output reg [31:0] MEM_WB_LMD_B,
output reg [2:0]  MEM_WB_TYPE_B,
output reg        MEM_WB_AGE_B
);

//====================================================
// OPCODES
//====================================================

parameter
    LOAD     = 7'b0000011,
    STORE    = 7'b0100011,

//====================================================
// TYPES
//====================================================

    TYPE_R   = 3'b000,
    TYPE_I   = 3'b001,
    TYPE_S   = 3'b010,
    TYPE_B   = 3'b011,
    TYPE_U   = 3'b100,
    TYPE_J   = 3'b101,
    TYPE_NOP = 3'b111;

//====================================================
// INTERNAL WIRES
//====================================================

wire [6:0] opcode;
wire [2:0] funct3;

assign opcode = EX_MEM_IR_B[6:0];
assign funct3 = EX_MEM_IR_B[14:12];

//====================================================
// DATA MEMORY WIRES
//====================================================

wire        mem_write;
wire        mem_read;

wire [31:0] mem_addr;
wire [31:0] mem_write_data;
wire [31:0] mem_read_data;

//====================================================
// LOAD / STORE WIRES
//====================================================

wire [31:0] load_data;
wire [31:0] store_data;

//====================================================
// MEMORY CONTROL
//====================================================

assign mem_read  = (opcode == LOAD);
assign mem_write = (opcode == STORE) & (~branched);

assign mem_addr = EX_MEM_ALUout_B;

//====================================================
// STORE MASKER
//====================================================

STORE_MASKER st_mask(
    .store_data(EX_MEM_X1_B),
    .funct3(funct3),
    .addr_offset(EX_MEM_ALUout_B[1:0]),
    .masked_data(store_data)
);

assign mem_write_data = store_data;

//====================================================
// DATA MEMORY
//====================================================

data_mem dmem(
    .clk(clk),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .addr(mem_addr),
    .write_data(mem_write_data),
    .read_data(mem_read_data)
);

//====================================================
// LOAD EXTENDER
//====================================================

LOAD_EXTENDER ld_ext(
    .mem_data(mem_read_data),
    .funct3(funct3),
    .addr_offset(EX_MEM_ALUout_B[1:0]),
    .load_data(load_data)
);

//====================================================
// MEM STAGE
//====================================================

always @(posedge clk)
begin

if(reset)
begin

    MEM_WB_IR_B      <= 32'd0;
    MEM_WB_ALUout_B  <= 32'd0;
    MEM_WB_LMD_B     <= 32'd0;
    MEM_WB_TYPE_B    <= TYPE_NOP;
    MEM_WB_AGE_B     <= 1'b0;

end

else
begin

    MEM_WB_IR_B      <= EX_MEM_IR_B;
    MEM_WB_ALUout_B  <= EX_MEM_ALUout_B;
    MEM_WB_TYPE_B    <= EX_MEM_TYPE_B;
    MEM_WB_AGE_B     <= EX_MEM_AGE_B;

    if(opcode == LOAD)
        MEM_WB_LMD_B <= load_data;

end

end

endmodule