`include "constants.v"
module Rob (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low


    //From Flow_Control
    input wire clr,
    input wire [3:0] Clear_Tag,

    //From Processor
    input wire ready,
    input wire [`Data_Bus] rd,
    input wire [16:0] name,
    input wire [`Data_Bus] Imm,

    //To Processor
    output reg success,

    //Public
    output wire [`ROB_Size] ROB_Valid,
    output wire [511:0] ROB_Imm,

    //From RS
    input wire RS_Ready,
    input wire [`Data_Bus] RS_A,
    input wire [`ROB_Width] RS_Tag,

    //To Register(Processor)
    output reg ROB_Ready,
    output reg [`Data_Bus] ROB_Value,
    output reg [`Register_Width] ROB_Addr,
    output reg[`ROB_Width] ROB_Tag,//nessecary when deciding whether to remove Tags[Rob_addr]

    //To Mem_ctrl
    output reg              RN,           //read_enable
    output reg              WN,
    output reg  [`Data_Bus] Wvalue,
    output reg  [`Data_Bus] Addr,
    input  wire             Mem_Success,
    input  wire [`Data_Bus] Read_Value
);
    reg [`Data_Bus] Rd[`ROB_Size];
    reg [16:0] Name[`ROB_Size];
    reg [`Data_Bus] A[`ROB_Size];
    reg Valid[`ROB_Size];
    reg Read_Able[`ROB_Size];
    reg [`ROB_Width] Tail = 1;  //To automatic overflow
    reg [`ROB_Width] Head = 0;  //To automatic overflow
    //add inst from Processor
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign ROB_Valid[i] = Valid[i];
            assign ROB_Imm[(i<<5)+31:(i<<5)] = A[i];
        end
    endgenerate
    wire HasRead;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign HasRead = HasRead | (Read_Able[i]);
        end
    endgenerate
    wire[`ROB_Width] Read_Tag =  Read_Able[0] ? 0 :
                                    Read_Able[1] ? 1 :
                                        Read_Able[2] ? 2 : 
                                            Read_Able[3] ? 3 :
                                                Read_Able[4] ? 4 :
                                                    Read_Able[5] ? 5 : 
                                                        Read_Able[6] ? 6 :
                                                            Read_Able[7] ? 7 :
                                                                Read_Able[8] ? 8 : 
                                                                    Read_Able[9] ? 9 :
                                                                        Read_Able[10] ? 10 :
                                                                            Read_Able[11] ? 11 :
                                                                                Read_Able[12] ? 12 :
                                                                                    Read_Able[13] ? 13 :
                                                                                        Read_Able[14] ? 14 : 
                                                                                            Read_Able[15] ? 15 :0;
    always @(posedge clk) begin
        if (rst) begin

        end else if (ready) begin
            if (Head == Tail) begin
                success <= `False;
            end else begin
                success <= `True;
                Rd[Tail] <= rd;
                Name[Tail] <= name;
                A[Tail] <= Imm;
                Valid[Tail] <= `False;
                Tail <= Tail + 1;
            end
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if(Valid[Head]&&(Name[Head]==`SB||Name[Head]==`SW||Name[Head]==`SH))begin
                WN <= `True;
                Wvalue <= A[Head];
                Addr <= Rd[Head];  //TODO CHECK
            end else if (HasRead) begin
                RN   <= `True;
                Addr <= A[Read_Tag];
            end else begin
                WN <= `False;
                RN <= `False;
            end
        end
    end
    //Push
    always @(posedge clk) begin
        if (rst) begin
        end else if (Valid[Head]) begin
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
                    ROB_Addr <= Rd[Head][3:0];
                    ROB_Tag <= Head;
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
                end else if (HasRead) begin
                    if (Read_Tag == Head) begin
                        Head <= Head + 1;
                        Valid[Head] <= `True;
                        ROB_Ready <= `True;
                        ROB_Addr <= Rd[Head][3:0];
                        ROB_Tag <= Head;
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
    always @(posedge clk) begin
        if (rst) begin

        end else if (clr) begin
            Tail <= Clear_Tag; //clear_tag and everything after it should be released
        end
    end
endmodule
