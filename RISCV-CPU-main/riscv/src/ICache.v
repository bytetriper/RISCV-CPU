`include "constants.v"
module ICache (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    output reg              IC_rn,     //read_enable(read only)
    output reg  [`Data_Bus] IC_addr,
    input  wire             IC_ready,
    input  wire [`Data_Bus] IC_value,


    input wire [31:0] addr,  //only 17:0 is used
    input wire rn,

    output reg [31:0] Inst,
    output reg ready
);

    reg [31:0] Cache[`Cache_Size:0][`Cache_Line:0];
    reg [22:0] Tag [`Cache_Size:0];//20=32-log(32(4 byte each))-log(8(Cache Size 8))-log(16(Cache_Line size))
    reg [31:0] PC;
    reg ToRam = `False;
    reg [31:0] Ram_Addr;
    reg [31:0] Ram_Addr_limit;
    always @(posedge clk) begin
        if (rst) begin
        end else if (ToRam) begin
            if (IC_ready) begin
                IC_rn <= `True;
                IC_addr <= Ram_Addr;
                Cache[PC[8:6]][Ram_Addr[5:2]] <= IC_value;
                Ram_Addr <= Ram_Addr + 4;
                if (Ram_Addr + 4 > Ram_Addr_limit) begin
                    ToRam <= `False;
                    IC_rn<=`False;
                    ready <= `True;
                    Inst  <= Cache[PC[8:6]][PC[5:2]];
                end
            end
        end else if (rn) begin
            PC <= addr;
            ready <= `False;
            if (Tag[addr[8:6]] == addr[31:9]) begin
                ready <= `True;
                Inst  <= Cache[addr[8:6]][addr[5:2]];
            end else begin
                ToRam <= `True;
                Tag[addr[8:6]] <= addr[31:9];
                Ram_Addr[31:9] <= addr[31:9];
                Ram_Addr_limit[31:9] <= addr[31:9];
                Ram_Addr_limit[8:0] <= 9'b11111100;
                Ram_Addr[8:0] <= 0;
            end
        end
    end
endmodule
