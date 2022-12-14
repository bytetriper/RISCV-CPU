`include "constants.v"
module Rob (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //TODO Read Dependency
    //From Flow_Control
    output reg clr,
    output reg [`Data_Bus] Clr_PC,

    //From Processor
    input wire ready,
    input wire [`Data_Bus] rd,
    input wire [16:0] name,
    input wire [`Data_Bus] Imm,
    input wire [`Data_Bus] PC,
    //To Processor
    output wire success,
    output wire [`ROB_Width] tail,
    //Public
    output wire [`ROB_Size] ROB_Valid,
    output wire [511:0] ROB_Imm,

    //From RS
    input wire RS_Ready,
    input wire [`Data_Bus] RS_A,
    input wire [`ROB_Width] RS_Tag,
    input wire [`Data_Bus] RS_Rd,

    //To RS
    output reg ROB_TO_RS_ready,
    output reg [3:0] ROB_TO_RS_Tag,
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
    output reg  [     16:0] Inst_Name,
    input  wire             Mem_Success,
    input  wire [`Data_Bus] Read_Value
);
    reg [`Data_Bus] Rd[`ROB_Size];
    reg [16:0] Name[`ROB_Size];
    reg [`Data_Bus] A[`ROB_Size];
    reg [`Data_Bus] ROB_PC[`ROB_Size];
    reg Valid[`ROB_Size];
    reg Read_Able[`ROB_Size];
    reg [`ROB_Width] Tail;  //To automatic overflow
    reg [`ROB_Width] Head;  //To automatic overflow
    assign tail = Tail;
    //add inst from Processor
    assign success = (Head != Tail + 1);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign ROB_Valid[i] = Valid[i];
            assign ROB_Imm[(i<<5)+31:(i<<5)] = A[i];
        end
    endgenerate
    wire HasRead;
    assign HasRead=Read_Able[0]
                    |Read_Able[1]
                        |Read_Able[2]
                            |Read_Able[3]
                                |Read_Able[4]
                                    |Read_Able[5]
                                        |Read_Able[6]
                                            |Read_Able[7]
                                                |Read_Able[8]
                                                    |Read_Able[9]
                                                        |Read_Able[10]
                                                            |Read_Able[11]
                                                                |Read_Able[12]
                                                                    |Read_Able[13]
                                                                        |Read_Able[14]
                                                                            |Read_Able[15];
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
    integer Log_File, cycle;
    integer k;
    reg [4:0] Working_ROB;  //ROB_Width+1
    initial begin
        for (k = 0; k < 16; k = k + 1) begin
            Valid[k] = 0;
            Read_Able[k] = 0;
        end
        RN = `False;
        WN = `False;
        Head = 1;
        Tail = 1;
        Wvalue = 0;
        Addr = 0;
        ROB_Ready = `False;
        ROB_Value = 0;
        ROB_Addr = 0;
        ROB_Tag = 0;
        ROB_TO_RS_ready = `False;
        clr = `False;
        Working_ROB = 16;
        Log_File = $fopen("ROB_LOG.txt", "w");
        cycle = 0;
    end
    reg [3:0] w;

    always @(posedge clk) begin
        cycle = cycle + 1;
        $fdisplay(Log_File, "Cycle:%d", cycle);
        for (w = Head; w != Tail; w = w + 1) begin
            $fdisplay(Log_File,
                      "[%d]Name:%x Rd:%d A:%x Readable:%d Valid:%d PC:%x", w,
                      Name[w], Rd[w], A[w], Read_Able[w], Valid[w], ROB_PC[w]);
        end
    end
    always @(posedge clr) begin
        $fdisplay(Log_File, "Cycle:%d", cycle);
        $fdisplay(Log_File, "Clear Signal Activated; PC:%x ", Clr_PC);
    end
    always @(posedge ready) begin
        if (rst) begin

        end else if (ready) begin
            if (Head == Tail + 1) begin
                ROB_TO_RS_ready = `False;
            end else begin
                Rd[Tail] = rd;
                Name[Tail] = name;
                ROB_PC[Tail] = PC;
                Valid[Tail] = `False;
                ROB_TO_RS_ready = `True;
                ROB_TO_RS_Tag = Tail;
                Tail = Tail + 1;
            end
        end else begin
            ROB_TO_RS_ready = `False;
        end
    end
    always @(negedge clk) begin//To make sure New Insts always come with a posedge ROB_TO_RS_ready
        ROB_TO_RS_ready = `False;
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
                    if (A[Head][0] ^ Rd[Head][0]) begin
                        clr <= `True;
                        if (A[Head][0]) begin
                            Clr_PC <= {Rd[Head][31:1], 1'b0};
                        end else begin
                            Clr_PC <= {A[Head][31:1], 1'b0};
                        end
                        Head <= Tail;  //Clear All
                    end else begin
                        ROB_Ready <= `False;
                        ROB_Addr <= `Empty;
                        ROB_Tag <= Head;
                        Head <= Head + 1;
                    end
                end
                `JALR: begin
                    clr <= `True;
                    Clr_PC <= {A[Head][31:1], 1'b0};
                    ROB_Ready <= `True;
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    ROB_Value <= ROB_PC[Head];
                    Head <= Tail;  //Clear All
                end
                `JAL: begin
                    ROB_Ready <= `True;
                    ROB_Value <= ROB_PC[Head];
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    Head <= Head + 1;
                end
                default: begin
                    ROB_Ready <= `True;
                    ROB_Value <= A[Head];
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    Head <= Head + 1;
                end
            endcase
        end else begin
            ROB_Ready <= `False;
        end
    end
    always @(negedge clk) begin  //Make sure A posedge Always happens
        ROB_Ready <= `False;
    end
    always @(posedge clk) begin  //Make Sure Clr always last for only one cycle
        if (clr) begin
            clr <= `False;
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if (Mem_Success) begin
                if(Valid[Head]&&(Name[Head]==`SB||Name[Head]==`SW||Name[Head]==`SH))begin
                    WN <= `True;
                    RN <= `False;
                    Wvalue <= A[Head];
                    Addr <= Rd[Head];
                    Inst_Name <= Name[Head];
                    Working_ROB <= {1'b0, Head};
                end else if (HasRead) begin
                    WN <= `False;
                    RN <= `True;
                    Addr <= A[Read_Tag];
                    Inst_Name <= Name[Head];
                    Working_ROB <= {1'b0, Read_Tag};
                end else begin
                    WN <= `False;
                    RN <= `False;
                    Working_ROB <= 16;
                end
                if (Working_ROB != 16) begin
                    case (Name[Working_ROB[3:0]])
                        `SB, `SW, `SH: begin
                        end
                        `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                            A[Working_ROB[3:0]] <= Read_Value;
                            Read_Able[Working_ROB[3:0]]<=`False;//Already Read
                        end
                        default: begin
                            $display("[Fatal Error]:Wrong Memory at ROB:%d",
                                     Working_ROB[3:0]);
                        end
                    endcase
                    if (Working_ROB[3:0] == Head) begin  //Commit
                        Head <= Head + 1;
                    end
                end
            end
        end
    end

    //Issue from RS
    always @(posedge clk) begin
        if (rst) begin
        end else if (RS_Ready) begin
            //assert occupied[RS_Tag] to be true here
            A[RS_Tag] <= RS_A;
            Valid[RS_Tag] <= `True;
            Rd[RS_Tag] <= RS_Rd;
        end
    end
    always @(negedge clk) begin  //Overclock
        if (rst) begin

        end else if (RS_Ready) begin
            case (Name[RS_Tag])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    Read_Able[RS_Tag] = (RS_A != 32'h30000);
                    for (w = Head; w != RS_Tag; w++) begin
                        case (Name[w])
                            `SB, `SH, `SW: begin
                                Read_Able[RS_Tag]=Read_Able[RS_Tag]&Valid[w]&(A[w]==RS_A);
                            end
                        endcase
                    end
                end
            endcase
        end
    end
endmodule
