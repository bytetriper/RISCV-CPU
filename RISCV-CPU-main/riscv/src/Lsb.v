`include "constants.v"
module LSB (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From ROB
    input wire Commit,
    //From Processor
    input wire ready,
    input wire [31:0] rd,
    input wire [31:0] name,
    input wire [31:0] Imm,
    input wire [3:0] tag,  //position in LSB

    //Back to Processor
    output reg success,
    //To Register(Processor)
    output reg LSB_Ready,
    output reg [31:0] LSB_Value,
    output reg [4:0] LSB_Addr,
    output reg[3:0] LSB_Tag,//nesscary when deciding whether to remove Tags[Rob_addr]
    //From RS
    input wire RS_Ready,
    input wire [31:0] RS_A,
    input wire [3:0] RS_Tag,
    input wire [31:0] RS_rd,

    //To Mem_ctrl
    output reg              RN,         //read_enable
    output reg              WN,         //Write_enable
    output reg  [`Data_Bus] Wvalue,
    output reg  [`Data_Bus] Addr,
    input  wire             Mem_ready,
    input  wire [`Data_Bus] Read_value
);
    reg [31:0] Rd[`LSB_Size];
    reg [31:0] Name[`LSB_Size];
    reg [31:0] A[`LSB_Size];
    reg [31:0] Tag[`LSB_Size];
    reg Valid[`LSB_Size];
    reg Occupied[`LSB_Size];
    reg [3:0] Tail = 0;  //To automatic overflow
    reg [3:0] Head = 1;  //To automatic overflow
    //add inst from Processor
    always @(posedge clk) begin
        if (rst) begin
        end else if (ready) begin
            if (Head == Tail) begin
                success <= `False;
            end else begin
                Rd[Tail] <= rd;
                Name[Tail] <= name;
                Tag[Tail] <= tag;
                Valid[Tail] <= `False;
                Occupied[Tail] <= `True;
                Tail <= Tail + 1;
            end
        end
    end
    //Read or Write
    always @(posedge clk) begin
        if (rst) begin
        end else if (Commit) begin
            case (Name[Head])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    RN   <= `True;
                    Addr <= A[Head];
                end
                `SB, `SH, `SW: begin
                    WN <= `True;
                    Addr <= Rd[Head];
                    Wvalue <= A[Head];
                end
            endcase
        end else begin
            RN <= `False;
            WN <= `False;
        end
    end
    //Push
    always @(posedge clk) begin//TODO remake
        if (rst) begin

        end else if (Mem_ready) begin
            case (Name[Head])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    LSB_Ready <= `True;
                    LSB_Addr  <= Rd[Head];
                    LSB_Value <= Read_value;
                    LSB_Tag   <= Tag[Head] + 16;
                end
                `SB, `SH, `SW: begin
                    //LSB_Ready<=`True;
                end
            endcase
            Occupied[Head] <= `False;
            Head <= Head + 1;
        end
    end
    //Commit from RS
    always @(posedge clk) begin
        if (rst) begin

        end else if (RS_Ready) begin
            //assert occupied[RS_Tag] to be true here
            A[RS_Tag] <= RS_A;
            Valid[RS_Tag] <= `True;
            Rd[RS_Tag] <= RS_rd;
            for(reg[3:0] i=RS_Tag;i!=Tail;i=i+1)//??
            {
                case (Name[i])
                    `LB,`LH,`LW:begin
                        if(Rd[i]==Rd[RS_Tag])begin
                          A[i]<=RS_A;
                          Valid[i]<=`True;
                        end
                    end
                endcase
            }
        end
    end
endmodule
