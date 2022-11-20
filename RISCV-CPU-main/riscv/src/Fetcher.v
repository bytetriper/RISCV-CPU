`include "constants.v"
module Fetcher (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire [31:0] Predict_Jump,//jump or +4

    //with ICache
    output reg [31:0] addr,  //only 17:0 is used
    output reg rn,  //read_enabled

    input wire [31:0] Inst,
    input wire Read_ready,

    output reg [31:0] CurrentAddr,
    output reg ready
);
    reg Reading = `False;
    reg [31:0] PC = 0;
    reg Instruction=0;
    always @(posedge clk) begin
        if (rst) begin

        end else if (!Reading) begin
            Reading <= `True;
            rn <= `True;
            addr<=Predict_Jump;
            PC<=Predict_Jump;
        end else begin
          if(Read_ready)begin//can instantly sent next addr here?
            Instruction<=Inst;
            Reading<=`False;
            rn<=`False;
            CurrentAddr<=Inst;
            ready<=`True;
            //maybe sent PC here
          end
        end
    end
endmodule
