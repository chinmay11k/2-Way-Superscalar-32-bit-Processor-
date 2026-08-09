module inst_mem(
    // read address port 0
    input  wire [31:0] addr0,
    // read address port 1
    input  wire [31:0] addr1,
    // instruction outputs
    output wire [31:0] inst0,
    output wire [31:0] inst1

);

reg [31:0] MEM [0:1500];
assign inst0 = MEM[addr0[31:2]];
assign inst1 = MEM[addr1[31:2]];
endmodule