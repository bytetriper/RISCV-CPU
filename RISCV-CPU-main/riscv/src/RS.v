`include "constants.v"
module RS (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //To Flow_Control
    output reg clr,
    output reg [`ROB_Width] Clear_Tag,
    output reg [`Data_Bus] PC,
    //From Proccessor

    input wire ready,
    input wire [`Data_Bus] rd,
    input wire [`Data_Bus] vj,
    input wire [`Data_Bus] vk,
    input wire [`Data_Bus] qj,
    input wire [`Data_Bus] qk,
    input wire [16:0] name,
    input wire [`Data_Bus] Imm,
    input wire [`ROB_Width] tag,  //position in ROB


    //To ROB
    output reg ROB_Ready,  //log(RS_Size)=log(16)=4
    output reg [`ROB_Width] ROB_Addr,
    output reg [`Data_Bus] ROB_A,

    //From ROB
    input wire [`ROB_Size] ROB_Valid,
    input wire [511:0] ROB_Value,  //32*ROB_Size-1:0
    //TO ALU
    output reg ALU_ready,
    input wire ALU_success,
    output reg [`Data_Bus] LV,
    output reg [`Data_Bus] RV,
    output reg[3:0]  Op,//Look Into "Constants.v" to see the definition of Operations
    input wire [`Data_Bus] result,

    //TO Predictor
    output reg Train_Ready,
    output reg Train_Result

);
    reg [`Data_Bus] Vj[`RS_Size];
    reg [`Data_Bus] Vk[`RS_Size];
    reg [`Data_Bus] Qj[`RS_Size];
    reg [`Data_Bus] Qk[`RS_Size];
    reg [`Data_Bus] A[`RS_Size];
    reg [16:0] Name[`RS_Size];
    reg [`ROB_Width] Tag[`RS_Size];
    reg [`Data_Bus] Rd[`RS_Size];
    wire [`Data_Bus] Tmp_Value[`ROB_Size];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign Tmp_Value[i] = ROB_Value[(i<<5)+31:i<<5];
        end
    endgenerate
    reg Busy [`RS_Size];
    reg Valid[`RS_Size];
    initial begin
        for (int i = 0; i < 16; i = i + 1) begin
            Busy[i]  = `True;
            Valid[i] = `False;
        end
    end
    reg [`RS_Width] Working_RS;
    wire HasFree;
    wire HasValid;
    wire [`RS_Width] valid_tag, free_tag;
    assign free_tag =  ~Busy[0] ? 0 :
                                ~Busy[1] ? 1 :
                                    ~Busy[2] ? 2 : 
                                        ~Busy[3] ? 3 :
                                            ~Busy[4] ? 4 :
                                                ~Busy[5] ? 5 : 
                                                    ~Busy[6] ? 6 :
                                                        ~Busy[7] ? 7 :
                                                            ~Busy[8] ? 8 : 
                                                                ~Busy[9] ? 9 :
                                                                    ~Busy[10] ? 10 :
                                                                        ~Busy[11] ? 11 :
                                                                            ~Busy[12] ? 12 :
                                                                                ~Busy[13] ? 13 :
                                                                                    ~Busy[14] ? 14 : 
                                                                                        ~Busy[15] ? 15 : 0;

    generate
        assign HasFree  = !Busy[0];
        assign HasValid = Valid[0];
        for (i = 1; i < 16; i = i + 1) begin
            assign HasFree  = HasFree | (!Busy[i]);
            assign HasValid = HasValid | Valid[i];
        end
    endgenerate
    assign valid_tag=  Valid[0] ? 0 :
                            Valid[1] ? 1 :
                                ~Valid[2] ? 2 : 
                                    ~Valid[3] ? 3 :
                                        ~Valid[4] ? 4 :
                                            ~Valid[5] ? 5 : 
                                                ~Valid[6] ? 6 :
                                                    ~Valid[7] ? 7 :
                                                        ~Valid[8] ? 8 : 
                                                            ~Valid[9] ? 9 :
                                                                ~Valid[10] ? 10 :
                                                                    ~Valid[11] ? 11 :
                                                                        ~Valid[12] ? 12 :
                                                                            ~Valid[13] ? 13 :
                                                                                ~Valid[14] ? 14 : 
                                                                                    ~Valid[15] ? 15 :0;
    always @(posedge clk) begin
        if (rst) begin

        end else if (ready) begin
            if (!HasFree) begin
                //Success <= `False;
            end else begin
                Vj[free_tag] <= vj;
                Qj[free_tag] <= qj;
                Vk[free_tag] <= vk;
                Qk[free_tag] <= qk;
                A[free_tag] <= Imm;
                Rd[free_tag] <= rd;
                Tag[free_tag] <= tag;
                Name[free_tag] <= name;
                Valid[free_tag] <= `False;
                Busy[free_tag] <= `True;
            end
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (HasValid) begin
            Working_RS <= valid_tag;
            ALU_ready <= `True;
            Valid[valid_tag] <= `False;  //Already Calculated
            case (Name[valid_tag])
                `LB, `LH, `LW, `LBU, `LHU, `LWU, `SB, `SH, `SW: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Add;
                    //A[IsValid]<=A[IsValid]+Vj[IsValid];
                end
                `AND: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&Vk[IsValid];
                end
                `ANDI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&A[IsValid];
                end
                `AUIPC: begin
                    LV <= Vj[valid_tag];
                    RV <= {A[valid_tag][31:12], 12'b0};
                    Op <= `Add;
                    //A[IsValid]<=Vj[IsValid]+{A[IsValid][31:12], 12'b0};
                end
                `BEQ: begin//SP for jumps,A[0] indicates the prediction 1:jump 0:not
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Equal;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGE: begin
                    LV <= $signed(Vj[valid_tag]);
                    RV <= $signed(Vk[valid_tag]);
                    Op <= `GEQ;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGEU: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `GEQ;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLT: begin
                    LV <= $signed(Vj[valid_tag]);
                    RV <= $signed(Vk[valid_tag]);
                    Op <= `Less;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLTU: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Less;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BNE: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `NotEqual;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JAL: begin
                    LV <= Vj[valid_tag];
                    RV <= {A[valid_tag][31:1], 1'b0};
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JALR: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+A[IsValid];
                end
                `OR: begin
                    ALU_ready <= `True;
                    RV <= Vk[valid_tag];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|Vk[IsValid];
                end
                `ORI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|A[IsValid];
                end
                `SLL: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<Vk[IsValid];
                end
                `SLLI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<A[IsValid];
                end
                `SLT: begin
                    LV <= $signed(Vj[valid_tag]);
                    RV <= $signed(Vk[valid_tag]);
                    Op <= `Less;
                end
                `SLTI: begin
                    LV <= $signed(Vj[valid_tag]);
                    RV <= $signed(A[valid_tag]);
                    Op <= `Less;
                end
                `SLTIU: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Less;
                end
                `SLTU: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Less;
                end
                `SRA: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `RightShift_A;
                end
                `SRAI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `RightShift_A;
                end
                `SRL: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `RightShift;
                end
                `SRLI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `RightShift;
                end
                `SUB: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Minus;
                end
                `XOR: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Xor;
                end
                `XORI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Xor;
                end
            endcase
        end else begin
            ALU_ready <= `False;
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (ALU_success) begin  //COMMIT
            A[Working_RS] <= result;
            Busy[Working_RS] <= `False;
            //Valid[Working_RS] <= `False;
            //Train Predictor
            case (Name[Working_RS])
                `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin
                    Train_Ready  <= `True;
                    Train_Result <= (A[Working_RS][0] & 1) ^ result[0];
                end
                default: begin
                    Train_Ready <= `False;
                end
            endcase
            //commit
            case (Name[Working_RS])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    ROB_Ready <= `True;
                    ROB_Addr <= Tag[Working_RS];
                    ROB_A <= result;
                end
                `SB, `SH, `SW: begin
                    ROB_Ready <= `True;
                    ROB_Addr <= Tag[Working_RS];
                    ROB_A <= result;
                end
                `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin
                    if (A[Working_RS][0] ^ result[0]) begin
                        clr <= `True;
                        Clear_Tag <= Tag[Working_RS];
                        PC <= Rd[Working_RS] + 4;  //TODO CHECK
                    end else begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= result;
                    end
                end
                `JALR: begin
                    clr <= `True;  //TODO:STUCK PC or CLEAR ALL?
                    Clear_Tag <= Tag[Working_RS];
                    PC <= Vk[Working_RS];
                end
                `JAL: begin
                    ROB_A <= result;  //SP
                    ROB_Ready <= `True;
                    ROB_Addr <= Tag[Working_RS];
                end
                default: begin
                    ROB_Ready <= `True;
                    ROB_Addr <= Tag[Working_RS];
                    ROB_A <= result;
                end
            endcase
            //Broadcast
        end
    end
    always @(posedge ready) begin//Introduce new inst into RS
            if (!HasFree) begin
            end else begin
                Vj[free_tag] = vj;
                Qj[free_tag] = qj;
                Vk[free_tag] = vk;
                Qk[free_tag] = qk;
                A[free_tag] = Imm;
                Rd[free_tag] = rd;
                Tag[free_tag] = tag;
                Name[free_tag] = name;
                Valid[free_tag] = `False;
                if(qj!=`Empty)begin
                    if(ROB_Valid[qj])begin
                        Vj[free_tag]=Tmp_Value[qj];
                        Qj[free_tag]=`Empty;
                    end
                end
                if(qk!=`Empty)begin
                    if(ROB_Valid[qk])begin
                        Vk[free_tag]=Tmp_Value[qk];
                        Qk[free_tag]=`Empty;
                    end
                end
                Busy[free_tag] = `True;//LAST indeed
            end
    end

    always @(posedge clk) begin
        for (integer i = 0; i < 16; i++) begin
            case (Name[i])
                default: begin
                    if (Qj[i] != `Empty) begin
                        if (ROB_Valid[Qj[i]]) begin
                            Qj[i] <= `Empty;
                            Vj[i] <= Tmp_Value[Qj[i]];
                        end
                    end
                    if (Qk[i] != `Empty) begin
                        if (ROB_Valid[Qk[i]]) begin
                            Qk[i] <= `Empty;
                            Vk[i] <= Tmp_Value[Qk[i]];
                        end
                    end
                end
            endcase
        end
    end
    //Make Sure clr is mostly false ;TODO CHECK
    always @(posedge clk) begin
        if (rst) begin

        end else if (clr) begin
            if(ALU_success&(A[Working_RS][0]^result[0]))begin
                //MAKE SURE CLR WOULDN'T BE PULLED THIS CYCLE
                case (Name[Working_RS])
                    `BEQ,`BGE,`BGEU,`BLT,`BLTU,`BNE:begin
                    end
                    default :begin
                        clr<=`False;
                    end
                endcase
            end else begin
                clr <= `False;
            end
        end
    end
endmodule
