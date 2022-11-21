`include "constants.v"
module RS (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Proccessor

    input wire ready,
    input wire [31:0] rd,
    input wire [31:0] vj,
    input wire [31:0] vk,
    input wire [31:0] qj,
    input wire [31:0] qk,
    input wire [31:0] name,
    input wire [31:0] Imm,
    input wire [3:0] tag,  //position in ROB or LSB

    //Back To Processor
    output reg Success,

    //To ROB
    output reg [ 3:0] ROB_Ready,  //log(RS_size)=log(16)=4
    output reg [31:0] ROB_A,
    output reg [4:0] ROB_Tag,

    //TO LSB
    output reg [ 3:0] LSB_Ready,  //
    output reg [31:0] LSB_A,
    output reg [31:0] LSB_Rd,
    output reg [4:0] LSB_Tag,
    //TO ALU
    output reg ALU_ready,
    input wire ALU_success,
    output reg [31:0] LV,
    output reg [31:0] RV,
    output reg[3:0]  Op,//Look Into "Constants.v" to see the definition of Operations
    input wire [31:0] result,

    //TO Predictor
    output reg Train_Ready,
    output reg Train_Result,
    output reg [31:0] Train_Name

);
    reg [31:0] Vj[`Rs_Size];
    reg [31:0] Vk[`Rs_Size];
    reg [31:0] Qj[`Rs_Size];
    reg [31:0] Qk[`Rs_Size];
    reg [31:0] A[`Rs_Size];
    reg [31:0] Name[`Rs_Size];
    reg [3:0] Tag[`Rs_Size];
    reg [31:0] Rd[`Rs_Size];
    reg Busy[`Rs_Size];
    reg Valid[`Rs_Size];
    reg Working_RS = `NO_RS_AVAILABLE;
    wire IsValid = 0;
    assign free_tag =  ~Busy[0] ? 1 :
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
                                                                                    ~Busy[15] ? 15 : `NO_RS_AVAILABLE;
    assign IsValid =  ~Valid[0] ? 1 :
                            ~Valid[1] ? 1 :
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
                                                                                    ~Valid[15] ? 15 : `NO_RS_AVAILABLE;
    always @(posedge clk) begin
        if (rst) begin

        end else if (ready) begin
            if (free_tag == `NO_RS_AVAILABLE) begin
                Success <= `False;
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

        end else if (IsValid != `NO_RS_AVAILABLE) begin
            Working_RS <= IsValid;
            ALU_ready <= `True;
            Valid[IsValid] <= `False;
            case (Name[IsValid])
                `LB, `LH, `LW, `LBU, `LHU, `LWU, `SB, `SH, `SW: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Add;
                    //A[IsValid]<=A[IsValid]+Vj[IsValid];
                end
                `AND: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&Vk[IsValid];
                end
                `ANDI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&A[IsValid];
                end
                `AUIPC: begin
                    LV <= Vj[IsValid];
                    RV <= {A[IsValid][31:12], 12'b0};
                    Op <= `Add;
                    //A[IsValid]<=Vj[IsValid]+{A[IsValid][31:12], 12'b0};
                end
                `BEQ: begin//SP for jumps,A[0] indicates the prediction 1:jump 0:not
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `Equal;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGE: begin
                    LV <= $signed(Vj[IsValid]);
                    RV <= $signed(Vk[IsValid]);
                    Op <= `GEQ;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGEU: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `GEQ;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLT: begin
                    LV <= $signed(Vj[IsValid]);
                    RV <= $signed(Vk[IsValid]);
                    Op <= `Less;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLTU: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `Less;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BNE: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `NotEqual;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JAL: begin
                    LV <= Vj[IsValid];
                    RV <= {A[IsValid][31:1], 1'b0};
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JALR: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+A[IsValid];
                end
                `OR: begin
                    ALU_ready <= `True;
                    RV <= Vk[IsValid];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|Vk[IsValid];
                end
                `ORI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|A[IsValid];
                end
                `SLL: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<Vk[IsValid];
                end
                `SLLI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<A[IsValid];
                end
                `SLT: begin
                    LV <= $signed(Vj[IsValid]);
                    RV <= $signed(Vk[IsValid]);
                    Op <= `Less;
                end
                `SLTI: begin
                    LV <= $signed(Vj[IsValid]);
                    RV <= $signed(A[IsValid]);
                    Op <= `Less;
                end
                `SLTIU: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Less;
                end
                `SLTU: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Less;
                end
                `SRA: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `RightShift_A;
                end
                `SRAI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `RightShift_A;
                end
                `SRL: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `RightShift;
                end
                `SRLI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `RightShift;
                end
                `SUB: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `Minus;
                end
                `XOR: begin
                    LV <= Vj[IsValid];
                    RV <= Vk[IsValid];
                    Op <= `Xor;
                end
                `XORI: begin
                    LV <= Vj[IsValid];
                    RV <= A[IsValid];
                    Op <= `Xor;
                end
            endcase
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (ALU_success) begin  //COMMIT
            A[Working_RS] <= result;
            Busy[Working_RS] <= `False;
            //Valid[Working_RS] <= `False;\
            //
            case (Name[Working_RS])
                `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU:begin
                  Train_Ready<=`True;
                    Train_Name<=Name[Working_RS];
                    Train_Result<=(A[Working_RS]&1)^result;
                end
                default:begin
                  Train_Ready<=`False;
                end
                    
            endcase
            //commit
            case (Name[Working_RS])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    LSB_Ready <= `True;
                    LSB_Tag<=Tag[Working_RS]-16;
                    LSB_A <= result;
                    LSB_Rd<=Rd[Working_RS];
                end
                 `SB, `SH, `SW:begin
                    LSB_Ready <= Tag[Working_RS];
                    LSB_Tag<=Tag[Working_RS]-16;
                    LSB_A <=Vk[Working_RS];
                    LSB_Rd<=result;
                 end
                `JALR,`JAL: begin
                    ROB_A <= result + 4;  //SP
                    ROB_Ready <= `True;
                    LSB_Tag<=Tag[Working_RS];
                end
                default: begin
                    ROB_Ready <= `True;
                    ROB_Tag<=Tag[Working_RS];
                    ROB_A <= result;
                end
            endcase
            //Broadcast
            case (Name[Working_RS])
                `ADD,`ADDI,`AND,`ANDI,`AUIPC,`OR,`ORI,`SLL,`SLLI,`SLT,`SLTI,`SLTIU,`SLTU,`SRA,`SRAI,`SRL,`SRLI,`SUB,`XOR,`XORI:begin
                    for (reg i = 0; i < 16; i = i + 1) begin
                        if (Qj[i] == Working_RS) begin
                            Qj[i] <= 0;
                            Vj[i] <= A[Working_RS];
                        end
                        if (Qk[i] == Working_RS) begin
                            Qk[i] <= 0;
                            Vk[i] <= A[Working_RS];
                        end
                    end
                end
                `JALR,`JAL: begin
                    for (reg i = 0; i < 16; i = i + 1) begin
                        if (Qj[i] == Working_RS) begin
                            Qj[i] <= 0;
                            Vj[i] <= A[Working_RS]+4;
                        end
                        if (Qk[i] == Working_RS) begin
                            Qk[i] <= 0;
                            Vk[i] <= A[Working_RS]+4;
                        end
                    end
                end
            endcase
        end
    end
endmodule
//todo JALR!!!
