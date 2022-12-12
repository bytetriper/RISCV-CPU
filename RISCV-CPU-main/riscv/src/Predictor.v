`include "constants.v"
module Predictor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Fetcher
    input wire Fetcher_Ready,
    input wire [`Data_Bus] PC,
    input wire [`Data_Bus] Inst,
    output reg [`Data_Bus] Predict_Jump,

    //From RS (Train)
    input wire Train_Ready,
    input wire Train_Result
);
    initial begin
        Predict_Jump = 0;
    end
    integer Imm;
    always @(PC) begin
        case (Inst[6:0])
            `SB_ALL: begin
                Imm = {20'b0, Inst[31], Inst[7], Inst[30:25], Inst[11:8]};
                if (1) begin
                    Predict_Jump = Imm + PC;
                end else begin
                    Predict_Jump = PC + 4;
                end
            end
            `UJ_JAL: begin
                Imm = {12'b0, Inst[31], Inst[19:12], Inst[20], Inst[30:21]};
                Predict_Jump = PC + Imm;
            end
            default: begin
                Predict_Jump = PC + 4;
            end
        endcase

    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (Train_Ready) begin
            //Todo Train
        end
    end
endmodule
