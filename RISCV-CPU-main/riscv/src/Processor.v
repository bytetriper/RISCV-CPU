`include "constants.v"
module Processor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Fetcher
    input wire [31:0] PC,
    input wire [31:0] Inst,
    input wire Inst_Ready,

    //To Fetcher
    output wire received,

    //From Flow Controler
    input wire clr,

    //To RS
    output reg ready,
    output reg [31:0] rd,
    output reg [31:0] vj,
    output reg [31:0] vk,
    output reg [31:0] qj,
    output reg [31:0] qk,
    output reg [16:0] name,
    output reg [31:0] Imm,
    //From ROB
    input wire success,
    //From ROB
    input wire ROB_Ready,
    input wire [31:0] ROB_Value,
    input wire [4:0] ROB_Addr,
    input wire[31:0] ROB_Tag,//nesscary when deciding whether to remove Tags[Rob_addr]

    //From Predictor
    input wire Predict_Jump
);
    reg [31:0] REGISTER[`Reg_Size];
    reg [31:0] Tags[`Reg_Size];
    assign received = success;
    integer Out_File;
    initial begin
        Out_File = $fopen("Error.txt", "w");
    end
    always @(posedge clk) begin
        if (rst) begin
        end else if (clr) begin
            //DO something maybe?
        end else if (Inst_Ready & success) begin
            //Decode:Opcode Inst[6:0]
            ready <= `True;
            case (Inst[6:0])
                `I_LOAD: begin  //Imm Extended TODO
                    rd <= {27'b0, Inst[11:7]};
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= {Tags[Inst[19:15]]};
                    end
                    begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    Imm<= {20'b0,Inst[31:20]};
                    //name <= (`I_LOAD << 10) | (Inst[14:12] << 7);
                    name <= {`I_LOAD, Inst[14:12], 7'b0};
                end
                `I_BINARY: begin
                    rd <= {27'b0, Inst[11:7]};
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    Imm <= {20'b0,Inst[31:20]};
                    name <= {`I_BINARY, Inst[14:12], 7'b0};
                end
                `U_AUIPC: begin
                    rd <= {27'b0, Inst[11:7]};
                    Imm<= {Inst[31:12],12'b0};
                    vj <= PC;
                    name <= `AUIPC;
                end
                `U_LUI: begin
                    rd <= {27'b0, Inst[11:7]};
                    Imm<= {Inst[31:12],12'b0};
                    name <= `LUI;
                end
                `S_SAVE: begin
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]] != `NO_RS_AVAILABLE) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end
                    /*
                    Imm[11:5] <= Inst[31:25];
                    Imm[4:0] <= Inst[11:7];*/
                    Imm<={20'b0,Inst[31:25],Inst[11:7]};
                    name <= {`S_SAVE, Inst[14:12], 7'b0};
                end
                `R_PRIMARY: begin
                    rd <= {27'b0, Inst[11:7]};
                    Imm<=0;
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]] != `NO_RS_AVAILABLE) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end
                    name <= {`R_PRIMARY, Inst[14:12], 7'b0};
                end
                `SB_ALL: begin
                    /*
                    Imm[11]   <= Inst[7];
                    Imm[4:1]  <= Inst[11:8];
                    Imm[12]   <= Inst[31];
                    Imm[10:5] <= Inst[30:25];
                    */
                    Imm <={20'b0,Inst[31],Inst[7],Inst[30:25],Inst[11:8]};
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]] != `NO_RS_AVAILABLE) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end
                    rd   <= {PC[31:1],Predict_Jump};
                    name <= {`SB_ALL, Inst[14:12], 7'b0};
                end
                `I_JALR: begin
                    rd <= {27'b0, Inst[11:7]};
                    if (Tags[Inst[19:15]] != `NO_RS_AVAILABLE) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    vk <= PC + 4;
                    //Imm[11:0] <= Inst[31:20];
                    Imm<= {20'b0,Inst[31:20]};
                    name <= `JALR;
                end
                `UJ_JAL: begin
                    rd <= {27'b0, Inst[11:7]};
                    vj <= PC + 4;  //risky
                    /*
                    Imm[20] <= Inst[31];
                    Imm[10:1] <= Inst[30:21];
                    Imm[11] <= Inst[20];
                    Imm[19:12] <= Inst[19:12];
                    */
                    Imm<= {12'b0,Inst[31],Inst[19:12],Inst[20],Inst[30:21]};
                    name <= `JAL;
                end
                default: begin
                    $fdisplay(Out_File, "[Fatal Error] %d", Inst);
                end
            endcase
        end else begin
            ready <= `False;
        end
    end
    always @(posedge ROB_Ready)begin//Update value
        if(rst)begin
            
        end else if(ROB_Ready)begin
            if(Tags[ROB_Addr]==ROB_Tag)begin  
                Tags[ROB_Addr]=`Empty;
                REGISTER[ROB_Addr]=ROB_Value;
            end
        end
    end
endmodule
