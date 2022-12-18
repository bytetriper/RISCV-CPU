`include "constants.v"
module Predictor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From ROB
    input wire clr,
    input wire [`Data_Bus] Target_PC,

    //From Fetcher
    input wire [`Data_Bus] PC,
    input wire [`Data_Bus] Inst,
    input wire Ready,
    //To Fetcher
    output reg [`Data_Bus] Predict_Jump,
    //To RS
    output reg Predict_Jump_Bool,
    //From RS (Train)
    input wire Train_Ready,
    input wire Train_Result
);
    integer Imm;
    reg Fixed;
    initial begin
        Predict_Jump = 0;
        Predict_Jump_Bool = `False;
        Fixed = `False;
    end

    always @(posedge clr) begin
        Fixed = `True;
        Predict_Jump = Target_PC;
    end
    always @(posedge Ready) begin
        if (Fixed&&PC!=Predict_Jump) begin
        end else begin
            case (Inst[6:0])
                `SB_ALL: begin
                    Imm = {
                        {19{Inst[31]}},
                        Inst[31],
                        Inst[7],
                        Inst[30:25],
                        Inst[11:8],
                        1'b0
                    };
                    if (1) begin
                        Predict_Jump = Imm + PC;
                        Predict_Jump = {15'b0, Predict_Jump[16:0]};
                        Predict_Jump_Bool = `True;
                    end else begin
                        Predict_Jump = PC + 4;
                        Predict_Jump = {15'b0, Predict_Jump[16:0]};
                        Predict_Jump_Bool = `False;
                    end
                end
                `UJ_JAL: begin
                    Imm = {
                        {11{Inst[31]}},
                        Inst[31],
                        Inst[19:12],
                        Inst[20],
                        Inst[30:21],
                        1'b0
                    };
                    //$display("UJJAL:%x,Imm:%x", Inst, Imm);
                    Predict_Jump = PC + Imm;
                    Predict_Jump = {15'b0, Predict_Jump[16:0]};
                    Predict_Jump_Bool = `True;
                end
                default: begin
                    Predict_Jump = PC + 4;
                    Predict_Jump = {15'b0, Predict_Jump[16:0]};
                    Predict_Jump_Bool = `False;
                end
            endcase
        end
        Fixed = `False;
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (Train_Ready) begin
            //Todo Train
        end
    end
endmodule
