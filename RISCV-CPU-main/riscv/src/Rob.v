`include "constants.v"
module Rob (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low


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
    output reg[3:0] ROB_Tag,//nesscary when deciding whether to remove Tags[Rob_addr]

    //To Mem_ctrl
    output reg              RN,           //read_enable
    output reg              WN,
    output reg  [`Data_Bus] Wvalue,
    output reg  [`Data_Bus] Addr,
    input  wire             Mem_Success,
    input  wire [`Data_Bus] Read_Value
);
    reg [31:0] Rd[`ROB_Size];
    reg [31:0] Name[`ROB_Size];
    reg [31:0] A[`ROB_Size];
    reg [31:0] Tag[`ROB_Size];
    reg Valid[`ROB_Size];
    reg Occupied[`ROB_Size];
    reg Read_Able[`ROB_Size];
    reg [3:0] Tail = 1;  //To automatic overflow
    reg [3:0] Head = 0;  //To automatic overflow
    //add inst from Processor
    assign Read_Tag =  ~Read_Able[0] ? 1 :
                            ~Read_Able[1] ? 1 :
                                ~Read_Able[2] ? 2 : 
                                    ~Read_Able[3] ? 3 :
                                        ~Read_Able[4] ? 4 :
                                            ~Read_Able[5] ? 5 : 
                                                ~Read_Able[6] ? 6 :
                                                    ~Read_Able[7] ? 7 :
                                                        ~Read_Able[8] ? 8 : 
                                                            ~Read_Able[9] ? 9 :
                                                                ~Read_Able[10] ? 10 :
                                                                    ~Read_Able[11] ? 11 :
                                                                        ~Read_Able[12] ? 12 :
                                                                            ~Read_Able[13] ? 13 :
                                                                                ~Read_Able[14] ? 14 : 
                                                                                    ~Read_Able[15] ? 15 : `NO_RS_AVAILABLE;
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
                Tail <= Tail + 1;
            end
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if(Valid[Head]&&(Valid[Head]==`SB||Valid[Head]==`SW||Valid[Head]==`SH))begin
                WN <= `True;
                Wvalue <= A[Head];
                Addr <= Rd[Head];  //TODO CHECK
            end else if (Read_Tag != `NO_RS_AVAILABLE) begin
                RN   <= `True;
                Addr <= A[Head];
            end else begin
                WN <= `False;
                RN <= `False;
            end
        end
    end
    //Push
    always @(posedge clk) begin
        if (rst) begin
        end else if (Occupied[Head] & Valid[Head]) begin
            case (Name[Head])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin

                end
                `SB, `SH, `SW: begin

                end
                `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin

                end
                `JALR, `JAL: begin

                end
                default: begin
                    ROB_Ready <= `True;
                    ROB_Value <= A[Head];
                    ROB_Addr <= Rd[Head];
                    ROB_Tag <= Tag[Head];
                    Head <= Head + 1;
                end
            endcase

        end else begin
            ROB_Ready <= `False;
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if (Mem_Success) begin
                if(Valid[Head]&&(Name[Head]==`SB||Name[Head]==`SW||Name[Head]==`SH))begin
                    Head <= Head + 1;
                end else if (Read_Tag != `NO_RS_AVAILABLE) begin
                    if (Read_Tag == Head) begin
                        Head <= Head + 1;
                        Valid[Head] <= `True;
                        ROB_Ready <= `True;
                        ROB_Addr <= Rd[Head];
                        ROB_Tag <= Tag[Head];
                        ROB_Value <= Read_Value;
                    end else begin
                        A[Head] <= Read_Value;
                    end
                end else begin
                    $display("Mem_success Error");
                end
            end
        end
    end

    //Commit from RS
    always @(posedge clk) begin
        if (rst) begin
        end else if (RS_Ready) begin
            //assert occupied[RS_Tag] to be true here
            A[RS_Tag] <= RS_A;
            Valid[RS_Tag] <= `True;
            case (Name[RS_Tag])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    Read_Able[RS_Tag] <= `True;
                end
            endcase
        end
    end
endmodule
