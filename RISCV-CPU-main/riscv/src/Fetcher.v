`include "constants.v"
module Fetcher (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire [`Data_Bus] Predict_Jump,  //jump or +4

    //From Flow Controler
    input wire clr,
    input wire [`Data_Bus] Target_PC,

    //To ICache
    output reg [`Data_Bus] addr,  //only 17:0 is used
    output reg rn,  //read_enabled
    

    //From ICache
    input wire [`Data_Bus] Inst,
    input wire Read_ready,
    
    //To Processor
    output reg [`Data_Bus] CurrentInst,
    output reg ready,

    //From Processor
    input wire success,
    //Exposed
    output wire [`Data_Bus] Out_PC
);
    reg Reading = `False;
    reg [31:0] PC = 32'b0;
    reg [31:0] Instruction = 32'b0;
    assign Out_PC =PC;
    always @(posedge clk) begin
        if (rst) begin

        end else if (clr) begin
            PC <= Target_PC;
        end else if ((!Reading)&success) begin
            Reading <= `True;
            rn <= `True;
            addr <= Predict_Jump;
            PC <= Predict_Jump;
        end else begin
            if (Read_ready) begin  //can instantly sent next addr here?
                Instruction <= Inst;
                Reading <= `False;
                rn <= `False;
                CurrentInst <= Inst;
                ready <= `True;
                //maybe sent PC here
            end
        end
    end
endmodule
