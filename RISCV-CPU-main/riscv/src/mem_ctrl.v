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
    integer BeZero = 1;
    reg startable = `True;  //is mem_ctrl occupied or not
    integer boss;  //the one who in process of reading(2-->LSB_Write 1 --> IC,0--> LSB)
    reg [`Data_Bus] data;
    reg [`Data_Bus] TmpAddr;
    initial begin
        data = 0;
        TmpAddr = 0;
        IC_ready = `True;
        IC_value = 0;
        mem_a = 0;
        mem_wr = 0;
        LSB_ready = `True;
        LSB_value = 0;
        boss = OffWork;
    end
    always @(Reading) begin  //indicating Reading 5 -> 0
        if (Reading == 0) begin
            if (boss == IC) begin
                IC_ready = `True;
            end
            if (boss == LSB_r) begin
                LSB_ready = `True;
            end
            if (boss == LSB_w) begin
                LSB_ready = `True;
            end
            boss = OffWork;
        end
    end
    always @(IC_addr) begin
        if (IC_rn) begin
            IC_ready = `False;
            if (boss == OffWork) begin
                boss = IC;
            end
        end
    end
    always @(LSB_addr) begin
        if (LSB_rn) begin
            LSB_ready = `False;
            if (boss == OffWork) begin
                boss = LSB_r;
            end
        end
        if (LSB_wn) begin
            LSB_ready = `False;
            if (boss == OffWork) begin
                boss = LSB_w;
            end
        end
    end
    always @(posedge clk) begin
        if (rst) begin  //Reset EveryThing!

        end else if (boss == 1 ) begin
            case (Reading)
                0: begin
                    mem_a   <= IC_addr;
                    mem_wr  <= `LOW;
                    TmpAddr <= IC_addr + 1;
                    Reading <= Reading + 1;

                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                2: begin
                    data[7:0] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                3: begin
                    data[15:8] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                4: begin
                    data[23:16] <= mem_dout;
                    Reading <= Reading + 1;

                end
                5: begin
                    data[31:24] <= mem_dout;
                    IC_value <= {mem_dout, data[23:0]};
                    Reading <= 0;
                end

            endcase
        end else if (boss == LSB_r ) begin
            case (Reading)
                0: begin
                    mem_a   <= LSB_addr;
                    mem_wr  <= `LOW;
                    Reading <= Reading + 1;
                    TmpAddr <= LSB_addr + 1;
                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                2: begin
                    data[7:0] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                3: begin
                    data[15:8] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                4: begin
                    data[23:16] <= mem_dout;
                    Reading <= Reading + 1;

                end
                5: begin
                    data[31:24] <= mem_dout;
                    LSB_value <= {mem_dout, data[23:0]};
                    Reading <= 0;

                end

            endcase
        end else if (boss == LSB_w) begin
            case (Reading)
                0: begin
                    mem_a   <= LSB_addr;
                    mem_wr  <= `HIGH;
                    mem_din <= LSB_Wvalue[7:0];
                    TmpAddr <= LSB_addr + 1;
                    Reading <= Reading + 1;

                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    mem_din <= LSB_Wvalue[15:8];
                    Reading <= Reading + 1;

                end
                2: begin
                    mem_din <= LSB_Wvalue[23:16];
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                3: begin
                    mem_din <= LSB_Wvalue[31:24];
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                4: begin
                    mem_wr  <= `LOW;  // Stop Writing Immediately
                    Reading <= 0;
                end
            endcase
        end
    end
endmodule
