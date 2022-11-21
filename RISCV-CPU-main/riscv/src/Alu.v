`include "constants.v"
module ALU (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire ALU_ready,
    output reg ALU_success,
    input wire [31:0] LV,
    input wire [31:0] RV,
    input wire[3:0]  Op,//Look Into "Constants.v" to see the definition of Operations
    output reg [31:0] result

);
    always @(posedge clk) begin
        if (rst) begin

        end else if (ALU_ready) begin
            ALU_success<=`True;
            case (Op)
                `Add:begin
                  result<=LV+RV;
                end
                `Minus:begin
                  result<=LV-RV;
                end
                `LeftShift:begin
                  result<=LV<<RV;
                end
                `RightShift:begin
                  result<=LV>>RV;
                end
                `RightShift_A:begin
                  result<=$signed(LV)>>RV ;
                end
            endcase
        end
    end
endmodule
