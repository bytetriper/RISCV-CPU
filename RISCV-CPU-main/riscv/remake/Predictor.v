`include "constants.v"
module Predictor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Fetcher
    input  wire [31:0] PC,
    input  wire [31:0] Imm,
    output reg  [31:0] Predict_Jump,

    //From RS (Train)
    input wire Train_Ready,
    input wire Train_Result,
    input wire [31:0] Name
);
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if (1) begin  //Unconditinally Predict True, for now
                Predict_Jump <= PC + Imm;
            end else begin
                Predict_Jump <= PC;
            end
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (Train_Ready) begin
            //Todo Train
        end
    end
endmodule
