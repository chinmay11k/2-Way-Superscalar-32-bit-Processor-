module STORE_MASKER(
input  [31:0] store_data,
input  [2:0]  funct3,
input  [1:0]  addr_offset,

output reg [31:0] masked_data
);

//===========================================
// STORE FUNCT3
//===========================================

parameter
    F3_SB   = 3'b000,
    F3_SH   = 3'b001,
    F3_SW   = 3'b010;

//===========================================
// MAIN LOGIC
//===========================================

always @(*)
begin

case(funct3)

//===========================================
// STORE BYTE
//===========================================

F3_SB:
begin

    case(addr_offset)

    2'b00:
        masked_data = {24'd0,store_data[7:0]};

    2'b01:
        masked_data = {16'd0,store_data[7:0],8'd0};

    2'b10:
        masked_data = {8'd0,store_data[7:0],16'd0};

    2'b11:
        masked_data = {store_data[7:0],24'd0};

    endcase

end

//===========================================
// STORE HALF
//===========================================

F3_SH:
begin

    case(addr_offset[1])

    1'b0:
        masked_data = {16'd0,store_data[15:0]};

    1'b1:
        masked_data = {store_data[15:0],16'd0};

    endcase

end

//===========================================
// STORE WORD
//===========================================

F3_SW:
    masked_data = store_data;

default:
    masked_data = 32'd0;

endcase

end

endmodule