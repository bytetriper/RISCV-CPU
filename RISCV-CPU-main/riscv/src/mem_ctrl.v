`include "constants.v"
module mem_ctrl (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    output reg  [ `Mem_Bus] mem_din,   // data input bus
    input  wire [ `Mem_Bus] mem_dout,  // data output bus
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
    localparam OffWork = 0, IC = 1, LSB_r = 2, LSB_w = 3;
    integer Reading = OffWork;
    reg BeZero = 1;
    reg startable = `True;  //is mem_ctrl occupied or not
    integer boss;  //the one who in process of reading(2-->LSB_Write 1 --> IC,0--> LSB)
    reg [`Data_Bus] data;
    reg[`Data_Bus] TmpAddr;
    always @(posedge clk) begin
        if (rst) begin  //Reset EveryThing!
            //boss?
            IC_ready <= `False;
            IC_value <= 0;
            LSB_ready <= `False;
            LSB_value <= 0;
            Reading <= OffWork;
            mem_din <= 0;
            mem_a <= 0;
            mem_wr <= 0;
            boss <= 0;
            Reading <= 0;
            startable <= `True;
        end else if (boss == 1 || (boss == OffWork & IC_rn)) begin
            if (boss == OffWork) begin
                IC_ready <= `False;
                LSB_ready<=`False;
                boss <= IC;
            end
            Reading <= (Reading + 1) * BeZero;
            case (Reading)
                0: begin
                    IC_ready <= `False;  //risky
                    mem_a <= IC_addr;
                    mem_wr <= `HIGH;
                    BeZero <= 1;
                    TmpAddr <= mem_a + 1;
                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr   <= TmpAddr + 1;
                end
                2: begin
                    data[7:0] <= mem_dout;
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                3: begin
                    data[15:8] <= mem_dout;
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                4: begin
                    data[23:16] <= mem_dout;
                    mem_a   <= TmpAddr;
                end
                5:begin
                    data[31:24] <= mem_dout;
                    IC_ready <= `True;
                    IC_value <= data;
                    BeZero <= 0;
                    boss <= 0;
                end

            endcase
        end else if (boss == LSB_r || (boss == OffWork & LSB_rn)) begin
            if (boss == OffWork) begin
                IC_ready <= `False;
                LSB_ready<=`False;
                boss <= LSB_r;
            end
            Reading <= (Reading + 1) * BeZero;
            case (Reading)
                0: begin
                    IC_ready <= `False;  //risky
                    mem_a <= IC_addr;
                    mem_wr <= `HIGH;
                    BeZero <= 1;
                    TmpAddr <= mem_a + 1;
                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr   <= TmpAddr + 1;
                end
                2: begin
                    data[7:0] <= mem_dout;
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                3: begin
                    data[15:8] <= mem_dout;
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                4: begin
                    data[23:16] <= mem_dout;
                    mem_a   <= TmpAddr;
                end
                5:begin
                    data[31:24] <= mem_dout;
                    LSB_ready <= `True;
                    LSB_value <= data;
                    BeZero <= 0;
                    boss <= 0;
                end

            endcase
        end else if (boss == LSB_w && (boss == OffWork && LSB_wn)) begin
            if (boss == OffWork) begin
                boss <= LSB_w;
                IC_ready <= `False;
                LSB_ready<=`False;
            end
            case (Reading)
                0: begin
                    IC_ready <= `False;  //risky
                    mem_a <= IC_addr;
                    mem_wr <= `LOW;
                    mem_din<= LSB_Wvalue[7:0];
                    BeZero <= 1;
                    TmpAddr <= mem_a + 1;
                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr   <= TmpAddr + 1;
                    mem_din<= LSB_Wvalue[15:8];
                end
                2: begin
                    mem_din<= LSB_Wvalue[23:16];
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                3: begin
                    mem_din<= LSB_Wvalue[31:24];
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                end
                4:begin
                    LSB_ready <= `True;
                    mem_wr<=`HIGH;// Stop Writing Immediately
                    BeZero <= 0;
                    boss <= 0;
                end
            endcase
        end
    end
endmodule
