module High_Bit(
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire[3:0] ROB_cnt,
    input wire[3:0] LSB_cnt, 
    output reg ROB_Spare,
    output reg LSB_Spare
);
always @(posedge clk) begin
    
end

endmodule
