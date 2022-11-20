`include "constants.v"
module Processor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire [31:0] PC,
    input wire [31:0] Inst,
    input wire [31:0] Inst_Ready,

    //To RS
    output reg ready,
    output reg [`Register_size] rd,
    output reg [`Register_size] vj,
    output reg [`Register_size] vk,
    output reg [`Register_size] qj,
    output reg [`Register_size] qk,
    output reg [31:0] Name,
    output reg [31:0] Imm
);
    reg [31:0] REGISTER[`Reg_Size];
    reg [31:0] Tags[`Reg_Size];
    always @(posedge clk) begin
        if (rst) begin
        end else if (Inst_Ready) begin
            //Decode:Opcode Inst[6:0]
            ready <= `True;
            case (Inst[6:0])
                `I_LOAD: begin  //Imm Extended undone
                    rd <= Inst[11:7];
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end
                    begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    Imm[11:0] <= Inst[31:20];
                    Name <= (`I_LOAD << 10) | (Inst[14:12] << 7) | (7'b0000000);
                    case ((Inst[14:12] << 7) | (7'b0000000))
                        `LB & `TAKEAWAY: begin

                        end
                        `LH & `TAKEAWAY: begin

                        end
                        `LW & `TAKEAWAY: begin

                        end
                        `LBU & `TAKEAWAY: begin

                        end
                        `LHU & `TAKEAWAY: begin

                        end
                        `LWU & `TAKEAWAY: begin

                        end
                    endcase
                end
                `I_BINARY: begin
                    rd <= Inst[11:7];
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    Imm[11:0] <= Inst[31:20];
                    Name <= (`I_BINARY << 10) | (Inst[14:12] << 7) | (7'b0000000);
                    case ((Inst[14:12] << 7) | (7'b0000000))
                        `ADDI & `TAKEAWAY: begin

                        end
                        `SLLI & `TAKEAWAY: begin

                        end
                        `SLTI & `TAKEAWAY: begin

                        end
                        `SLTIU & `TAKEAWAY: begin

                        end
                        `XORI & `TAKEAWAY: begin

                        end
                        `SRLI & `TAKEAWAY: begin

                        end
                        `SRAI & `TAKEAWAY: begin

                        end
                        `ORI & `TAKEAWAY: begin

                        end
                        `ANDI & `TAKEAWAY: begin

                        end
                    endcase
                end
                `U_AUIPC: begin
                    rd <= Inst[11:7];
                    Imm[31:12] <= Inst[31:12];
                    vj <= PC;
                end
                `U_LUI: begin
                    rd <= Inst[11:7];
                    Imm[31:12] <= Inst[31:12];
                end
                `S_SAVE: begin
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]]) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end

                    Imm[11:5] <= Inst[31:25];
                    Imm[4:0] <= Inst[11:7];
                    Name <= (`S_SAVE << 10) | (Inst[14:12] << 7) | (7'b0000000);
                    case ((Inst[14:12] << 7) | (7'b0000000))
                        `SB & `TAKEAWAY: begin

                        end
                        `SH & `TAKEAWAY: begin

                        end
                        `SW & `TAKEAWAY: begin

                        end
                    endcase
                end
                `R_PRIMARY: begin
                    rd <= Inst[11:7];
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]]) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end
                    Name <= (`R_PRIMARY << 11) | (Inst[14:12] << 7) | (Inst[31:25]);
                    case ((Inst[14:12] << 7) | (Inst[31:25]))
                        `ADD & `TAKEAWAY: begin

                        end
                        `SUB & `TAKEAWAY: begin

                        end
                        `SLL & `TAKEAWAY: begin

                        end
                        `SLT & `TAKEAWAY: begin

                        end
                        `SLTU & `TAKEAWAY: begin

                        end
                        `XOR & `TAKEAWAY: begin

                        end
                        `SRL & `TAKEAWAY: begin

                        end
                        `SRA & `TAKEAWAY: begin

                        end
                        `OR & `TAKEAWAY: begin

                        end
                        `AND & `TAKEAWAY: begin

                        end
                    endcase
                end
                `SB_ALL: begin
                    Imm[11]   <= Inst[7];
                    Imm[4:1]  <= Inst[11:8];
                    Imm[12]   <= Inst[31];
                    Imm[10:5] <= Inst[30:25];
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    if (Tags[Inst[24:20]]) begin
                        qk <= Tags[Inst[24:20]];
                    end else begin
                        vk <= REGISTER[Inst[24:20]];
                        qk <= 0;
                    end
                    rd <= PC;
                    Name <= (`SB_ALL << 10) | (Inst[14:12] << 7) | (7'b0000000);
                    case ((Inst[14:12] << 7) | (7'b0000000))
                        `BEQ & `TAKEAWAY: begin

                        end
                        `BNE & `TAKEAWAY: begin

                        end
                        `BLT & `TAKEAWAY: begin

                        end
                        `BGE & `TAKEAWAY: begin

                        end
                        `BLTU & `TAKEAWAY: begin

                        end
                        `BGEU & `TAKEAWAY: begin

                        end
                    endcase
                end
                `I_JALR: begin
                    rd <= Inst[11:7];
                    if (Tags[Inst[19:15]]) begin
                        qj <= Tags[Inst[19:15]];
                    end else begin
                        vj <= REGISTER[Inst[19:15]];
                        qj <= 0;
                    end
                    rd <= PC + 4;
                    Imm[11:0] <= Inst[31:20];
                    Name <= (`I_JALR << 10) | (10'b0000000000);
                end
                `UJ_JAL: begin
                    rd <= Inst[11:7];
                    vk <= PC;
                    Imm[20] <= Inst[31];
                    Imm[10:1] <= Inst[30:21];
                    Imm[11] <= Inst[20];
                    Imm[19:12] <= Inst[19:12];
                    Name <= (`UJ_JAL << 10) | (10'b0000000000);
                end
            endcase
        end else
            begin
              ready<=`False;
            end
    end
endmodule
