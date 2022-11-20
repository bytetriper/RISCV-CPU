`include "constants.v"
module Rob (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Flow_Controler
    input wire Spare,

    //From Processor
    input wire ready,
    input wire [31:0] rd,
    input wire [31:0] name,
    input wire [31:0] Imm,
    input wire [3:0] tag,  //position in RS

    //To Processor
    output reg success,

    //From RS
    input wire RS_Ready,
    input wire [31:0] RS_A,
    input wire [3:0] RS_Tag,

    //To Register(Processor)
    output reg ROB_Ready,
    output reg [31:0] ROB_Value,
    output reg [4:0] ROB_Addr,
    output reg[3:0] ROB_Tag//nesscary when deciding whether to remove Tags[Rob_addr]
);
    reg [31:0] Rd[`ROB_Size];
    reg [31:0] Name[`ROB_Size];
    reg [31:0] A[`ROB_Size];
    reg [31:0] Tag[`ROB_Size];
    reg Valid[`ROB_Size];
    reg Occupied[`ROB_Size];
    reg [3:0] Tail = 0;//To automatic overflow
    reg [3:0] Head = 1;//To automatic overflow
    //add inst from Processor
    always @(posedge clk) begin
        if (rst) begin

        end else if (ready) begin
            if (Head == Tail) begin
                success <= `False;
            end else begin
                Rd[Tail] <= rd;
                Name[Tail] <= name;
                A[Tail] <= Imm;
                Tag[Tail] <= tag;
                Valid[Tail] <= `False;
                Occupied[Tail]<=`True;
                Tail <= Tail + 1;
            end
        end
    end
    //Push
    always @(posedge clk) begin
        if (rst) begin

        end else if (Occupied[Head]&Valid[Head] & Spare) begin
            ROB_Ready <= `True;
            ROB_Addr  <= Rd[Head];
            ROB_Value <= A[Head];
            ROB_Tag   <= Tag[Head];
            Head<=Head+1;
        end
    end
    //Commit from RS
    always @(posedge clk) begin
        if(rst)begin
          
        end else if(RS_Ready)begin
          //assert occupied[RS_Tag] to be true here
            A[RS_Tag]<=RS_A;
        end
    end
endmodule
