module reg_file_module(

    input wire clk,
    input wire reset,

    input  wire [4:0] rs1_A,
    input  wire [4:0] rs2_A,

    input  wire [4:0] rs1_B,
    input  wire [4:0] rs2_B,

    output wire [31:0] rs1_data_A,
    output wire [31:0] rs2_data_A,

    output wire [31:0] rs1_data_B,
    output wire [31:0] rs2_data_B,

    input wire write_en_A,
    input wire [4:0] rd_A,
    input wire [31:0] write_data_A,
    input wire        age_A,

    input wire write_en_B,
    input wire [4:0] rd_B,
    input wire [31:0] write_data_B,
    input wire        age_B

);

reg [31:0] REG [0:31];

always @(negedge clk)
begin

    if(!reset)
    begin

        if(write_en_A && write_en_B && (rd_A == rd_B) && (rd_A != 5'd0))
        begin
            // Resolve simultaneous writes to the same destination using age.
            // Higher age means younger instruction, so younger write wins.
            if(age_A < age_B)
                REG[rd_A] <= write_data_B;
            else
                REG[rd_A] <= write_data_A;
        end
        else
        begin
            if(write_en_A && (rd_A != 5'd0))
                REG[rd_A] <= write_data_A;

            if(write_en_B && (rd_B != 5'd0))
                REG[rd_B] <= write_data_B;
        end

    end

end

assign rs1_data_A = (rs1_A == 5'd0) ? 32'd0 : REG[rs1_A];
assign rs2_data_A = (rs2_A == 5'd0) ? 32'd0 : REG[rs2_A];

assign rs1_data_B = (rs1_B == 5'd0) ? 32'd0 : REG[rs1_B];
assign rs2_data_B = (rs2_B == 5'd0) ? 32'd0 : REG[rs2_B];

endmodule