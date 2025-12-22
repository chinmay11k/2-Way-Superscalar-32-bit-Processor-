`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: RedsunIP
// Engineer: Chinmay Kulkarni
// 
// Create Date: 15.10.2025 10:19:39
// Design Name: 
// Module Name: Superscaler_32_inorder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Superscaler_32_inorder(
input clk1,clk2);

reg [31:0]REG[0:31];
reg [31:0]MEM[0:1023];

//program counter
reg [31:0]PC;

//1st latches IF_ID
reg [31:0] IF_ID_IR_0,IF_ID_IR_1,IF_ID_NPC_0,IF_ID_NPC_1;

//2nd latches ID_EX
reg [31:0] ID_EX_IR_A,ID_EX_NPC_A,ID_EX_X0_A,ID_EX_X1_A,ID_EX_IMM_A;// X0,X1 are data stored in rs1,rs2
reg [2:0] ID_EX_TYPE_A;//for pipe A which is for ALU oparations and branch and jump oparations 
reg [2:0] ID_EX_TYPE_0;
reg [31:0] ID_EX_IR_B,ID_EX_NPC_B,ID_EX_X0_B,ID_EX_X1_B,ID_EX_IMM_B;// X0,X1 are data stored in rs1,rs2
reg [2:0] ID_EX_TYPE_B;//for pipe A which is for ALU oparations and Memory oparations 
reg [2:0] ID_EX_TYPE_1;
reg [1:0] FU_type_X0; 
reg [1:0] FU_type_X1; 

//3rd Latches EX_MEM
// for FU A
reg [31:0]EX_MEM_ALUout_A,EX_MEM_IR_A;  
reg [2:0] EX_MEM_TYPE_A;//needed for geting rd 
reg [31:0]EX_MEM_X1_A;
//for FU B
reg [31:0]EX_MEM_ALUout_B,EX_MEM_LMD,EX_MEM_IR_B;//str = data that to be stored in memory 
reg [2:0] EX_MEM_TYPE_B;// needed for geting rd 
reg [31:0]EX_MEM_X1_B;

wire [31:0]ALUout_A;
wire [31:0]ALUout_B;

//4th Latches MEM_WB
// wait latched for FU A 
reg [31:0]MEM_WB_ALUout_A,MEM_WB_IR_A;  
reg [2:0] MEM_WB_TYPE_A;

// req for only FU B 
reg [31:0] MEM_WB_IR_B,MEM_WB_ALUout_B,MEM_WB_LMD_B;//lmd=load memory data(for load oparation 
reg[2:0] MEM_WB_TYPE_B;

// parameters 
//for opcode 
parameter 
// R type 
    ADD  = 6'b000000,
    SUB  = 6'b000001,
    MUL  = 6'b000010,
    AND  = 6'b000011,
    OR   = 6'b000100,
    XOR  = 6'b000101,
    SLL  = 6'b000110,
    SRL  = 6'b000111,
    //I type
    ADDI = 6'b001000,
    SUBI = 6'b001001,
    ANDI = 6'b001010,
    ORI  = 6'b001011,
    XORI = 6'b001100,
    // mem type 
    LW   = 6'b010000,
    SW   = 6'b010001,
    //branch type 
    BEQ  = 6'b011000,
    BNE  = 6'b011001,
    BLT  = 6'b011010,
    BGE  = 6'b011011,
    //jump type 
    J    = 6'b100000,
    JAL  = 6'b100001,
    
    //no oparations 
    NOP  = 6'b111111;

// PARAMETER FOR TYPE OF INSTRUCTION
parameter
//types 
ALUtype=2'b00,
MEMtype=2'b01,
B_Jtype=2'b10,
//subtypes 
RR_ALU=3'b000, 
RI_ALU=3'b001,
LOAD=3'b010,
STORE=3'b011,
BRANCH=3'b100,
JUMP=3'B101,
Nop=3'b111;


reg stall_IF,stall_ID,stall_Ex;
reg branched,jump;


// Instruction fetch stage 
always@(posedge clk1)
if(stall_IF==0)
    begin
        if(branched==1||jump==1)//cheaking is we require to branching in prev instruction
            begin
                  IF_ID_NPC_0<=EX_MEM_ALUout_A+2;
                  IF_ID_NPC_1<=EX_MEM_ALUout_A+3;
                  PC<=EX_MEM_ALUout_A+1;
                  branched <= 1'b0;
                  IF_ID_IR_0<= MEM[EX_MEM_ALUout_A];
                  IF_ID_IR_1<= MEM[EX_MEM_ALUout_A+1];
                end
        else
            begin
                IF_ID_NPC_0<= PC+2;
                IF_ID_NPC_1<= PC+3;
                PC<= PC+2;
                IF_ID_IR_0<= MEM[PC];
                IF_ID_IR_1<= MEM[PC+1];
                end
     end   

//ID STAGE
//Instruction decode logic 
//always@(IF_ID_IR_0,IF_ID_IR_1)
always@(*)
        begin
        case(IF_ID_IR_0[31:26])
                          ADD:  ID_EX_TYPE_0 <=  RR_ALU;
                          SUB:  ID_EX_TYPE_0 <=  RR_ALU;
                          MUL:  ID_EX_TYPE_0 <=  RR_ALU;
                          AND:  ID_EX_TYPE_0 <=  RR_ALU;
                          OR:   ID_EX_TYPE_0 <=  RR_ALU;
                          SLL:  ID_EX_TYPE_0 <=  RR_ALU;
                          SRL:  ID_EX_TYPE_0 <=  RR_ALU;
                          //i type 
                          ADDI: ID_EX_TYPE_0 <=  RI_ALU;
                          SUBI: ID_EX_TYPE_0 <=  RI_ALU;
                          ANDI: ID_EX_TYPE_0 <=  RI_ALU;
                          ORI: ID_EX_TYPE_0 <=  RI_ALU;
                          XORI: ID_EX_TYPE_0 <=  RI_ALU;
                        //mem type 
                          LW:   ID_EX_TYPE_0 <=  LOAD;
                          SW:   ID_EX_TYPE_0 <=  STORE;
                          //brach type 
                          BEQ: ID_EX_TYPE_0 <=  BRANCH;
                          BNE:ID_EX_TYPE_0 <=  BRANCH;
                          BLT:ID_EX_TYPE_0 <=  BRANCH;
                          BGE:ID_EX_TYPE_0 <=  BRANCH;
                         //jump
                          J:ID_EX_TYPE_0 <=  JUMP;
                          JAL:ID_EX_TYPE_0 <=  JUMP;
                         //nop
                          NOP: ID_EX_TYPE_0 <=  Nop;
                      default: 
                            ID_EX_TYPE_0<=  Nop;//default halt
                    endcase
                    
        case(IF_ID_IR_1[31:26])
                          ADD:  ID_EX_TYPE_1 <=  RR_ALU;
                          SUB:  ID_EX_TYPE_1 <=  RR_ALU;
                          MUL:  ID_EX_TYPE_1 <=  RR_ALU;
                          AND:  ID_EX_TYPE_1 <=  RR_ALU;
                          OR:   ID_EX_TYPE_1 <=  RR_ALU;
                          SLL:  ID_EX_TYPE_1 <=  RR_ALU;
                          SRL:  ID_EX_TYPE_1 <=  RR_ALU;
                          //i type         1
                          ADDI: ID_EX_TYPE_1 <=  RI_ALU;
                          SUBI: ID_EX_TYPE_1 <=  RI_ALU;
                          ANDI: ID_EX_TYPE_1 <=  RI_ALU;
                          ORI: ID_EX_TYPE_1  <=  RI_ALU;
                          XORI: ID_EX_TYPE_1 <=  RI_ALU;
                        //mem type         1
                          LW:   ID_EX_TYPE_1 <=  LOAD;
                          SW:   ID_EX_TYPE_1 <=  STORE;
                          //brach type 
                          BEQ: ID_EX_TYPE_1 <=  BRANCH;
                          BNE:ID_EX_TYPE_1<=  BRANCH;
                          BLT:ID_EX_TYPE_1<=  BRANCH;
                          BGE:ID_EX_TYPE_1<=  BRANCH;
                         //jump
                          J:ID_EX_TYPE_1 <=  JUMP;
                          JAL:ID_EX_TYPE_1 <=  JUMP;
                         //nop
                          NOP: ID_EX_TYPE_1 <=  Nop;
                      default: 
                            ID_EX_TYPE_1<=  Nop;//default halt
                                endcase            
 end    
 
 always@(ID_EX_TYPE_1,ID_EX_TYPE_0)
begin
          //catagatrising in top cata gories for easier issue 
            case(ID_EX_TYPE_0)
                RR_ALU: FU_type_X0 <= ALUtype; 
                RI_ALU: FU_type_X0 <= ALUtype; 
                LOAD  : FU_type_X0 <= MEMtype; 
                STORE : FU_type_X0 <= MEMtype; 
                BRANCH: FU_type_X0 <= B_Jtype; 
                JUMP  : FU_type_X0 <= B_Jtype;      
                endcase           
            case(ID_EX_TYPE_1)
                RR_ALU: FU_type_X1 <= ALUtype; 
                RI_ALU: FU_type_X1 <= ALUtype; 
                LOAD  : FU_type_X1 <= MEMtype; 
                STORE : FU_type_X1 <= MEMtype; 
                BRANCH: FU_type_X1 <= B_Jtype; 
                JUMP  : FU_type_X1 <= B_Jtype; 
//                Nop=3'b111;
            endcase 
end

//Instruction decode and issue logic
always@(posedge clk2)
begin
if(stall_ID==0)
        begin
         case (FU_type_X0)
            ALUtype:begin
                        case(FU_type_X1)
                            ALUtype:begin
                                   ID_EX_IR_A<=IF_ID_IR_0;
                                   ID_EX_NPC_A<=IF_ID_NPC_0;
                                   ID_EX_X0_A<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                   ID_EX_X1_A<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]]; 
                                   ID_EX_IMM_A<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                   
                                   ID_EX_IR_B<=IF_ID_IR_1;
                                   ID_EX_NPC_B<=IF_ID_NPC_1;
                                   ID_EX_X0_B<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                   ID_EX_X1_B<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]];
                                   ID_EX_IMM_B<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};
                                   
                                   ID_EX_TYPE_A<=ID_EX_TYPE_0;
                                   ID_EX_TYPE_B<=ID_EX_TYPE_1;    
                                    end
                                    
                            MEMtype:begin
                                   ID_EX_IR_A<=IF_ID_IR_0;
                                   ID_EX_NPC_A<=IF_ID_NPC_0;
                                   ID_EX_X0_A<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                   ID_EX_X1_A<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]]; 
                                   ID_EX_IMM_A<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                   
                                   ID_EX_IR_B<=IF_ID_IR_1;
                                   ID_EX_NPC_B<=IF_ID_NPC_1;
                                   ID_EX_X0_B<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                   ID_EX_X1_B<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]];
                                   ID_EX_IMM_B<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};      
                                   ID_EX_TYPE_A<=ID_EX_TYPE_0;
                                   ID_EX_TYPE_B<=ID_EX_TYPE_1;    

                                     end
                                                                        
                            B_Jtype:begin
                                       ID_EX_IR_A<=IF_ID_IR_1;
                                       ID_EX_NPC_A<=IF_ID_NPC_1;
                                       ID_EX_X0_A<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                       ID_EX_X1_A<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]]; 
                                       ID_EX_IMM_A<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};
                                       
                                       ID_EX_IR_B<=IF_ID_IR_0;
                                       ID_EX_NPC_B<=IF_ID_NPC_0;
                                       ID_EX_X0_B<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                       ID_EX_X1_B<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]];
                                       ID_EX_IMM_B<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};         
                                       ID_EX_TYPE_A<=ID_EX_TYPE_1;
                                       ID_EX_TYPE_B<=ID_EX_TYPE_0;    
       
                                     end
                        endcase
                        end
               
            MEMtype:begin
                        case(FU_type_X1)
                                        ALUtype:begin
                                        ID_EX_IR_A<=IF_ID_IR_1;
                                        ID_EX_NPC_A<=IF_ID_NPC_1;
                                        ID_EX_X0_A<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                        ID_EX_X1_A<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]]; 
                                        ID_EX_IMM_A<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};
                                        
                                        ID_EX_IR_B<=IF_ID_IR_0;
                                        ID_EX_NPC_B<=IF_ID_NPC_0;
                                        ID_EX_X0_B<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                        ID_EX_X1_B<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]];
                                        ID_EX_IMM_B<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};                

                                        ID_EX_TYPE_A<=ID_EX_TYPE_1;
                                        ID_EX_TYPE_B<=ID_EX_TYPE_0;    

                                                end
                                                
                                        MEMtype:begin
                                                stall_IF<=1;
                                                stall_ID<=1;
                                                ID_EX_IR_B<=IF_ID_IR_0;
                                                ID_EX_NPC_B<=IF_ID_NPC_0;
                                                ID_EX_X0_B<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                                ID_EX_X1_B<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]];
                                                ID_EX_IMM_B<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                                ID_EX_TYPE_B<=ID_EX_TYPE_0;    

                                                 end
                                                                                    
                                        B_Jtype:begin
                                        ID_EX_IR_A<=IF_ID_IR_1;
                                        ID_EX_NPC_A<=IF_ID_NPC_1;
                                        ID_EX_X0_A<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                        ID_EX_X1_A<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]]; 
                                        ID_EX_IMM_A<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};
                                        
                                        ID_EX_IR_B<=IF_ID_IR_0;
                                        ID_EX_NPC_B<=IF_ID_NPC_0;
                                        ID_EX_X0_B<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                        ID_EX_X1_B<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]];
                                        ID_EX_IMM_B<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};                
                                        ID_EX_TYPE_A<=ID_EX_TYPE_1;
                                        ID_EX_TYPE_B<=ID_EX_TYPE_0;    

                                                 end
                                    endcase
                 end
                                                    
            B_Jtype:begin
                                        case(FU_type_X1)
                                        ALUtype:begin
                                                 ID_EX_IR_A<=IF_ID_IR_0;
                                                 ID_EX_NPC_A<=IF_ID_NPC_0;
                                                 ID_EX_X0_A<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                                 ID_EX_X1_A<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]]; 
                                                 ID_EX_IMM_A<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                                 
                                                 ID_EX_IR_B<=IF_ID_IR_1;
                                                 ID_EX_NPC_B<=IF_ID_NPC_1;
                                                 ID_EX_X0_B<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                                 ID_EX_X1_B<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]];
                                                 ID_EX_IMM_B<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};      
                                                 ID_EX_TYPE_A<=ID_EX_TYPE_0;
                                                 ID_EX_TYPE_B<=ID_EX_TYPE_1;    

                                                end
                                                
                                        MEMtype:begin
                                                  ID_EX_IR_A<=IF_ID_IR_0;
                                                  ID_EX_NPC_A<=IF_ID_NPC_0;
                                                  ID_EX_X0_A<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                                  ID_EX_X1_A<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]]; 
                                                  ID_EX_IMM_A<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                                  
                                                  ID_EX_IR_B<=IF_ID_IR_1;
                                                  ID_EX_NPC_B<=IF_ID_NPC_1;
                                                  ID_EX_X0_B<=(IF_ID_IR_1[25:21]==5'b00000)?0:REG[IF_ID_IR_1[25:21]];
                                                  ID_EX_X1_B<=(IF_ID_IR_1[20:16]==5'b00000)?0:REG[IF_ID_IR_1[20:16]];
                                                  ID_EX_IMM_B<={{16{IF_ID_IR_1[15]}},{IF_ID_IR_1[15:0]}};      
                                                  ID_EX_TYPE_A<=ID_EX_TYPE_0;
                                                  ID_EX_TYPE_B<=ID_EX_TYPE_1;    

                                                 end
                                                                                    
                                        B_Jtype:begin
                                                    stall_IF<=1;
                                                    stall_ID<=1;
               
                                                    ID_EX_IR_A<=IF_ID_IR_0;
                                                    ID_EX_NPC_A<=IF_ID_NPC_0;
                                                    ID_EX_X0_A<=(IF_ID_IR_0[25:21]==5'b00000)?0:REG[IF_ID_IR_0[25:21]];
                                                    ID_EX_X1_A<=(IF_ID_IR_0[20:16]==5'b00000)?0:REG[IF_ID_IR_0[20:16]]; 
                                                    ID_EX_IMM_A<={{16{IF_ID_IR_0[15]}},{IF_ID_IR_0[15:0]}};
                                                    ID_EX_TYPE_A<=ID_EX_TYPE_0;    

                                                 end
                                    endcase
                 end                                                                                             
        endcase
        end
   
else// condition to send 1 data path after stalling 
begin
end
end


//Ex stage

//ALU declearation
ALU alu_A(
                .A(ID_EX_X0_A),
                .B(ID_EX_X1_A),
                .IMM(ID_EX_IMM_A),
                .NPC(ID_EX_NPC_A),
                .func(ID_EX_IR_A[31:26]),
                .type(ID_EX_TYPE_A),
                .ALUout(ALUout_A));
                
ALU alu_B(
                .A(ID_EX_X0_B),
                .B(ID_EX_X1_B),
                .IMM(ID_EX_IMM_B),
                .NPC(ID_EX_NPC_B),
                .func(ID_EX_IR_B[31:26]),
                .type(ID_EX_TYPE_B),
                .ALUout(ALUout_B));

always@(posedge clk1)
begin
if(stall_Ex==0)
begin
        EX_MEM_TYPE_A<= ID_EX_TYPE_A;
        EX_MEM_TYPE_B<= ID_EX_TYPE_B;

        EX_MEM_IR_A<= ID_EX_IR_A;
        EX_MEM_IR_B<= ID_EX_IR_B;

        case(ID_EX_IR_A[31:26])
        BEQ:begin
            if(ID_EX_X0_A==ID_EX_X1_A)
            begin
            branched<=1;
            end
         end
        BNE:begin
        if(ID_EX_X0_A!=ID_EX_X1_A)
                    begin
                    branched<=1;
                    end
        end
        BLT:begin
        if(ID_EX_X0_A<ID_EX_X1_A)
                    begin
                    branched<=1;
                    end
        end
        BGE:begin
        if(ID_EX_X0_A>=ID_EX_X1_A)
                    begin
                    branched<=1;
                    end
        end
        J  :begin
                    begin
                    branched<=1;
                    end
                end
 
        JAL:begin
                    begin
                    branched<=1;
                    end
        end
         
        endcase
        EX_MEM_X1_B<=ID_EX_X1_B;

        EX_MEM_ALUout_A<=ALUout_A;
        EX_MEM_ALUout_B<=ALUout_B;
        end

end



//mem stage 
always@(posedge clk2)
begin
        MEM_WB_TYPE_A<= EX_MEM_TYPE_A;
        MEM_WB_TYPE_B<= EX_MEM_TYPE_B;

        MEM_WB_IR_A<=EX_MEM_IR_A;
        MEM_WB_IR_B<=EX_MEM_IR_B;
        
        MEM_WB_ALUout_A<=EX_MEM_ALUout_A;
        
        case(EX_MEM_TYPE_B)
            RR_ALU,RI_ALU: MEM_WB_ALUout_B<= EX_MEM_ALUout_B;
            
            LOAD:
                  MEM_WB_LMD_B<= MEM[EX_MEM_ALUout_B];
            
            STORE:if(branched==0)                // disable write
                     MEM[EX_MEM_ALUout_B]<= EX_MEM_X1_B;
    endcase

        

end

//WB STAGE
always@(posedge clk1)
begin
    if(branched==0)
    begin
        case(MEM_WB_TYPE_A)
            RR_ALU: REG[MEM_WB_IR_A[15:11]]<=  MEM_WB_ALUout_A;//rd
            RI_ALU:REG[MEM_WB_IR_A[20:16]]<=  MEM_WB_ALUout_A;//rt
            LOAD:REG[MEM_WB_IR_A[20:16]]<=  MEM_WB_ALUout_A;//rt
    endcase
            case(MEM_WB_TYPE_B)
        RR_ALU: REG[MEM_WB_IR_B[15:11]]<=  MEM_WB_ALUout_B;//rd
        RI_ALU:REG[MEM_WB_IR_B[20:16]]<=  MEM_WB_ALUout_B;//rt
        LOAD:REG[MEM_WB_IR_B[20:16]]<=  MEM_WB_ALUout_B;//rt
    endcase
    end
    end
endmodule
