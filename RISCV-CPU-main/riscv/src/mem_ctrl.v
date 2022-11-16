module mem_ctrl
(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
	input  wire					        rdy,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output reg  [ 7:0]          mem_dout,		// data output bus
  output reg  [31:0]          mem_a,			// address bus (only 17:0 is used)
  output reg                  mem_wr,			// write/read signal (1 for write)

    //For ICache

    input wire               IC_rn,//read_enable
    input wire[31:0]               PC,
    output reg                      IC_ready,
    output reg [31:0]               IC_value
);
always @(posedge clk) begin
    if(rst)begin//Reset EveryThing!
        IC_ready<=0;
        IC_value <=0;
        mem_dout<=0;
        mem_a<=0;
        mem_wr<=0;
    end

    if(IC_rn)begin
      
    end
end
endmodule