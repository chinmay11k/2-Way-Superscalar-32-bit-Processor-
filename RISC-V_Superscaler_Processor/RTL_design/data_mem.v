module data_mem(

input wire clk,

input wire mem_write,
input wire mem_read,

input wire [31:0] addr,

input wire [31:0] write_data,

output reg [31:0] read_data

);

//====================================================
// BYTE ADDRESSABLE MEMORY
//====================================================

reg [7:0] MEM [0:63];

//====================================================
// WRITE LOGIC
//====================================================

always @(posedge clk)
begin

    if(mem_write)
    begin

        MEM[addr]     <= write_data[7:0];
        MEM[addr + 1] <= write_data[15:8];
        MEM[addr + 2] <= write_data[23:16];
        MEM[addr + 3] <= write_data[31:24];

    end

end

//====================================================
// READ LOGIC
//====================================================

always @(*)
begin

    if(mem_read)
    begin

        read_data =
        {
            MEM[addr + 3],
            MEM[addr + 2],
            MEM[addr + 1],
            MEM[addr]
        };

    end

    else
    begin

        read_data = 32'd0;

    end

end

endmodule