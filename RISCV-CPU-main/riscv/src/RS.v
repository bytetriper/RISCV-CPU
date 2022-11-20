`include "constants.v"
module RS (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Proccessor

    input wire ready,
    input wire [`Register_size] rd,
    input wire [`Register_size] vj,
    input wire [`Register_size] vk,
    input wire [`Register_size] qj,
    input wire [`Register_size] qk,
    input wire [31:0] name,
    input wire [31:0] Imm,

    //To ROB
    output reg [4:0] ROB_Ready,  //log(RS_size)=log(16)=4

    //TO LSB
    output reg [4:0] LSB_Ready,  //

    //TO ALU
    output reg [31:0] LV,
    output reg [31:0] RV,
    output reg[2:0]  Op//Look Into "Constants.v" to see the definition of Operations
);
    reg [31:0] Vj[`Rs_Size];
    reg [31:0] Vk[`Rs_Size];
    reg [31:0] Qj[`Rs_Size];
    reg [31:0] Qk[`Rs_Size];
    reg [31:0] A[`Rs_Size];
    reg [31:0] Name[`Rs_Size];
    reg [31:0] Occupied[`Rs_Size];
    reg [31:0] Valid[`Rs_Size];
    wire IsValid=0;
    always @(posedge clk) begin
        if (rst) begin

        end else if (ready) begin

        end
    end
endmodule
