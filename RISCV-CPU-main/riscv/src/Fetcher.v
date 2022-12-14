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
    output reg [`Data_Bus] Out_PC
);
    reg [`Data_Bus] PC ;
    reg [`Data_Bus] Inst_Buffer;
    initial begin
        ready = `False;
        rn = `False;
        PC=32'b0;
        Inst_Buffer=32'b0;
    end
    always @(negedge clk) begin
        ready<=`False;
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (clr) begin
            PC<=Target_PC;
            rn<=`True;
            addr<=Target_PC;
            Out_PC<=0;
            ready<=`False;
        end else if (Read_ready) begin
            if (success) begin
                rn <= `True;
                addr <= Predict_Jump;
                ready <= `True;
                CurrentInst <= Inst;
                PC <= Predict_Jump;
                Out_PC<= PC;
            end else begin
                rn <= `False;
            end
        end else begin
            
        end
    end
endmodule
