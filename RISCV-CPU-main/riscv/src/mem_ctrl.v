`include "constants.v"
module mem_ctrl (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input  wire [ `Mem_Bus] mem_din,   // data input bus
    output reg  [ `Mem_Bus] mem_dout,  // data output bus
    output reg  [`Data_Bus] mem_a,     // address bus (only 17:0 is used)
    output reg              mem_wr,    // write/read signal (1 for write)

    //For ICache

    input  wire             IC_rn,     //read_enable(read only)
    input  wire [`Data_Bus] IC_addr,
    output reg              IC_ready,
    output reg  [`Data_Bus] IC_value,


    //For LSB
    input  wire             LSB_rn,      //read_enable
    input  wire             LSB_wn,      //Write_enable
    input  wire [`Data_Bus] LSB_Wvalue,
    input  wire [`Data_Bus] LSB_addr,
    output reg              LSB_ready,
    output reg  [`Data_Bus] LSB_value
);
    reg Reading = `False;
    reg working = `False, starter = `True;  //is mem_ctrl occupied or not
    reg boss;  //the one who in process of reading(2-->LSB_Write 1 --> IC,0--> LSB)
    reg [`Data_Bus] data;
    localparam OffWork = 0, IC = 1, LSB_r = 2, LSB_w = 3;
    always @(posedge clk) begin
        if (rst) begin  //Reset EveryThing!
            //boss?
            IC_ready <= `False;
            IC_value <= 0;
            LSB_ready <= `False;
            LSB_value <= 0;
            Reading <= `False;
            mem_dout <= 0;
            mem_a <= 0;
            mem_wr <= 0;
            working <= 0;
            boss <= 0;
            Reading <= 0;
            starter<=`True;
        end else if (boss == 1 || (boss==OffWork & IC_rn)) begin
            if (!boss) begin
                IC_ready <= `False;
                boss <= IC;
                starter <= `False;
            end
            if (!working | starter) begin
                case (Reading)
                    0: begin
                        IC_ready <= `False;  //risky
                        mem_a <= IC_addr;
                        mem_wr <= `HIGH;
                        Reading <= Reading + 1;
                    end
                    1: begin
                        data[7:0] <= mem_din;
                        Reading   <= Reading + 1;
                    end
                    2: begin
                        data[15:8] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    3: begin
                        data[23:16] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    4: begin
                        data[31:24] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    5: begin
                        IC_ready <= `True;
                        IC_value <= data;
                        Reading <= 0;
                        boss <= 0;
                        starter <= `True;
                    end
                endcase
            end
            working <= working ^ 1;
        end else if (boss == LSB_r || (boss==OffWork & LSB_rn)) begin
            if (!boss) begin
                LSB_ready <= `False;
                boss <= LSB_r;
                starter <= `False;
            end
            if (!working) begin
                case (Reading)
                    0: begin
                        mem_a   <= LSB_addr;
                        mem_wr  <= `HIGH;
                        Reading <= Reading + 1;
                    end
                    1: begin
                        data[7:0] <= mem_din;
                        Reading   <= Reading + 1;
                    end
                    2: begin
                        data[15:8] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    3: begin
                        data[23:16] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    4: begin
                        data[31:24] <= mem_din;
                        Reading <= Reading + 1;
                    end
                    5: begin
                        LSB_ready <= `True;
                        LSB_value <= data;
                        Reading <= 0;
                        boss <= 0;
                        starter <= `True;
                    end
                endcase
            end
            working <= working ^ 1;
        end else if (boss == LSB_w && (boss==OffWork && LSB_wn)) begin
            if (!boss) begin
                boss <= LSB_w;
                LSB_ready <= `False;
                starter <= `False;
            end
            if (!working) begin//guarantee that after every work,working is false?
                case (Reading)
                    0: begin
                        mem_a <= LSB_addr;
                        mem_wr <= `LOW;
                        Reading <= Reading + 1;
                        data <= LSB_Wvalue;
                    end
                    1: begin
                        mem_dout <= data[7:0];
                        Reading  <= Reading + 1;
                    end
                    2: begin
                        mem_dout <= data[15:8];
                        Reading  <= Reading + 1;
                    end
                    3: begin
                        mem_dout <= data[23:16];
                        Reading  <= Reading + 1;
                    end
                    4: begin
                        mem_dout <= data[31:24];
                        Reading  <= Reading + 1;
                    end
                    5: begin
                        Reading <= 0;
                        LSB_ready <= `True;
                        boss <= 0;
                        starter <= `True;
                    end
                endcase
            end
            working <= working ^ 1;
        end
    end
endmodule
