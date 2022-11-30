// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
ICache u_ICache(
  .clk      (clk      ),
  .rst      (rst      ),
  .rdy      (rdy      ),
  .IC_rn    (IC_rn    ),
  .IC_addr  (IC_addr  ),
  .IC_ready (IC_ready ),
  .IC_value (IC_value ),
  .addr     (addr     ),
  .rn       (rn       ),
  .Inst     (Inst     ),
  .ready    (ready    )
);

mem_ctrl 
#(
  .OffWork (OffWork ),
  .IC      (IC      ),
  .LSB_r   (LSB_r   ),
  .LSB_w   (LSB_w   )
)
u_mem_ctrl(
  .clk        (clk        ),
  .rst        (rst        ),
  .rdy        (rdy        ),
  .mem_din    (mem_din    ),
  .mem_dout   (mem_dout   ),
  .mem_a      (mem_a      ),
  .mem_wr     (mem_wr     ),
  .IC_rn      (IC_rn      ),
  .IC_addr    (IC_addr    ),
  .IC_ready   (IC_ready   ),
  .IC_value   (IC_value   ),
  .LSB_rn     (LSB_rn     ),
  .LSB_wn     (LSB_wn     ),
  .LSB_Wvalue (LSB_Wvalue ),
  .LSB_addr   (LSB_addr   ),
  .LSB_ready  (LSB_ready  ),
  .LSB_value  (LSB_value  )
);


ram 
#(
  .ADDR_WIDTH (ADDR_WIDTH )
)
u_ram(
  .clk_in  (clk_in  ),
  .en_in   (en_in   ),
  .r_nw_in (r_nw_in ),
  .a_in    (a_in    ),
  .d_in    (d_in    ),
  .d_out   (d_out   )
);
ALU u_ALU(
  .clk         (clk         ),
  .rst         (rst         ),
  .rdy         (rdy         ),
  .ALU_ready   (ALU_ready   ),
  .ALU_success (ALU_success ),
  .LV          (LV          ),
  .RV          (RV          ),
  .Op          (Op          ),
  .result      (result      )
);
Flow_Control u_Flow_Control(
  .RS_Stop (RS_Stop ),
  .RS_Tag  (RS_Tag  ),
  .PC      (PC      ),
  .clr     (clr     ),
  .PC_out  (PC_out  ),
  .Tag     (Tag     )
);
Processor u_Processor(
  .clk        (clk        ),
  .rst        (rst        ),
  .rdy        (rdy        ),
  .PC         (PC         ),
  .Inst       (Inst       ),
  .Inst_Ready (Inst_Ready ),
  .clr        (clr        ),
  .Target_PC  (Target_PC  ),
  .ready      (ready      ),
  .rd         (rd         ),
  .vj         (vj         ),
  .vk         (vk         ),
  .qj         (qj         ),
  .qk         (qk         ),
  .name       (name       ),
  .Imm        (Imm        ),
  .ROB_Ready  (ROB_Ready  ),
  .ROB_Value  (ROB_Value  ),
  .ROB_Addr   (ROB_Addr   ),
  .ROB_Tag    (ROB_Tag    ),
  .LSB_Ready  (LSB_Ready  ),
  .LSB_Value  (LSB_Value  ),
  .LSB_Addr   (LSB_Addr   ),
  .LSB_Tag    (LSB_Tag    )
);
Rob u_Rob(
  .clk         (clk         ),
  .rst         (rst         ),
  .rdy         (rdy         ),
  .clr         (clr         ),
  .Clear_Tag   (Clear_Tag   ),
  .ready       (ready       ),
  .rd          (rd          ),
  .name        (name        ),
  .Imm         (Imm         ),
  .tag         (tag         ),
  .success     (success     ),
  .ROB_Valid   (ROB_Valid   ),
  .ROB_Imm     (ROB_Imm     ),
  .RS_Ready    (RS_Ready    ),
  .RS_A        (RS_A        ),
  .RS_Tag      (RS_Tag      ),
  .ROB_Ready   (ROB_Ready   ),
  .ROB_Value   (ROB_Value   ),
  .ROB_Addr    (ROB_Addr    ),
  .ROB_Tag     (ROB_Tag     ),
  .RN          (RN          ),
  .WN          (WN          ),
  .Wvalue      (Wvalue      ),
  .Addr        (Addr        ),
  .Mem_Success (Mem_Success ),
  .Read_Value  (Read_Value  )
);
Predictor u_Predictor(
  .clk          (clk          ),
  .rst          (rst          ),
  .rdy          (rdy          ),
  .PC           (PC           ),
  .Imm          (Imm          ),
  .Predict_Jump (Predict_Jump ),
  .Train_Ready  (Train_Ready  ),
  .Train_Result (Train_Result ),
  .Name         (Name         )
);
Fetcher u_Fetcher(
  .clk          (clk          ),
  .rst          (rst          ),
  .rdy          (rdy          ),
  .Predict_Jump (Predict_Jump ),
  .clr          (clr          ),
  .Target_PC    (Target_PC    ),
  .addr         (addr         ),
  .rn           (rn           ),
  .Inst         (Inst         ),
  .Read_ready   (Read_ready   ),
  .CurrentAddr  (CurrentAddr  ),
  .ready        (ready        )
);

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule