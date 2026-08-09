module LOAD_EXTENDER(
input  [31:0] mem_data,
input  [2:0]  funct3,
input  [1:0]  addr_offset,

output reg [31:0] load_data
);

//===========================================
// LOAD FUNCT3
//===========================================

parameter
    F3_LB   = 3'b000,
    F3_LH   = 3'b001,
    F3_LW   = 3'b010,
    F3_LBU  = 3'b100,
    F3_LHU  = 3'b101;

//===========================================
// INTERNAL REGS
//===========================================

reg [7:0]  byte_data;
reg [15:0] half_data;

//===========================================
// BYTE SELECT
//===========================================

always @(*)
begin

case(addr_offset)

2'b00: byte_data = mem_data[7:0];
2'b01: byte_data = mem_data[15:8];
2'b10: byte_data = mem_data[23:16];
2'b11: byte_data = mem_data[31:24];

endcase

case(addr_offset[1])

1'b0: half_data = mem_data[15:0];
1'b1: half_data = mem_data[31:16];

endcase

case(funct3)

F3_LB:
    load_data = {{24{byte_data[7]}},byte_data};

F3_LBU:
    load_data = {24'd0,byte_data};

F3_LH:
    load_data = {{16{half_data[15]}},half_data};

F3_LHU:
    load_data = {16'd0,half_data};

F3_LW:
    load_data = mem_data;

default:
    load_data = 32'd0;

endcase

end

endmodule