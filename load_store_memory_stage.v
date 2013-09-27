`include "load_store_memory_stage_define.v"

module load_store_memory_stage(
				input clk_in,
				input reset_in,
				input [`LOAD_STORE_MEMORY_STAGE_CONTROL_WORD-1:0] load_store_memory_stage_control_word_in,
				output [`LOAD_STORE_MEMORY_STAGE_RD_DATA-1:0] data_frm_mem_out,
				output load_store_multiple_en_out,
				output load_store_memory_stage_complete_out,
				output load_store_memory_stage_instr_confirmed_out,
				output [`LOAD_STORE_MEMORY_STAGE_RN_DATA-1:0] load_store_rn_data_out,
				output [`LOAD_STORE_MEMORY_STAGE_RD_ADDR-1:0] load_store_rd_addr_out,
				output [`LOAD_STORE_MEMORY_STAGE_RN_ADDR-1:0] load_store_rn_addr_out,
				output [`LOAD_STORE_MEMORY_STAGE_INSTR_TAG-1:0] load_store_instr_tag_out
    );

wire [`LOAD_STORE_MEMORY_STAGE_ADDRESS-1:0] addr_to_mem;
wire [`LOAD_STORE_MEMORY_STAGE_RD_DATA-1:0] store_data;
wire [`LOAD_STORE_MEMORY_STAGE_RN_DATA-1:0] load_store_rn_data;
wire [`LOAD_STORE_MEMORY_STAGE_W_EN-1:0] w_en;
wire swp_ctrl,load_store_instr_confirmed,load_store_multiple_en;
wire [`LOAD_STORE_MEMORY_STAGE_CTRL_LOAD_MUX-1:0] ctrl_load_mux;
wire [`LOAD_STORE_MEMORY_STAGE_CTRL_STR_MUX-1:0] ctrl_str_mux;
wire [`LOAD_STORE_MEMORY_STAGE_RD_ADDR-1:0] load_store_rd_addr;
wire [`LOAD_STORE_MEMORY_STAGE_RN_ADDR-1:0] load_store_rn_addr;
wire [`LOAD_STORE_MEMORY_STAGE_INSTR_TAG-1:0] load_store_instr_tag;


/******ADDR_TO_MEM******/
assign addr_to_mem = load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_ADDRESS_START:
`LOAD_STORE_MEMORY_STAGE_ADDRESS_END];
/******ADDR_TO_MEM******/

/******STORE_DATA******/
assign store_data = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_STORE_RD_DATA_START:
`LOAD_STORE_MEMORY_STAGE_STORE_RD_DATA_END];
/******STORE_DATA******/

/******W_EN******/
assign w_en = load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_WRITE_EN_START:
`LOAD_STORE_MEMORY_STAGE_WRITE_EN_END];
/******W_EN******/

/******SWP_CTRL******/
assign swp_ctrl = load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_SWP_CTRL];
/******SWP_CTRL******/

/******CTRL_LOAD_MUX******/
assign ctrl_load_mux = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_CTRL_LOAD_MUX_START:
`LOAD_STORE_MEMORY_STAGE_CTRL_LOAD_MUX_END];
/******CTRL_LOAD_MUX******/

/******CTRL_STR_MUX******/
assign ctrl_str_mux = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_CTRL_STR_MUX_START:
`LOAD_STORE_MEMORY_STAGE_CTRL_STR_MUX_END];
/******CTRL_STR_MUX******/

/******LOAD_STORE_MEMORY_STAGE_COMPLETE******/
assign load_store_memory_stage_complete = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_START];
/******LOAD_STORE_MEMORY_STAGE_COMPLETE******/

/******LOAD_STORE_MEMORY_STAGE_INSTR_CONFIRMED******/
assign load_store_instr_confirmed = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_INSTR_CONFIRMED];
/******LOAD_STORE_MEMORY_STAGE_INSTR_CONFIRMED******/

/******LOAD_STORE_MULTIPLE_EN******/
assign load_store_multiple_en = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_MULTIPLE_EN];
/******LOAD_STORE_MULTIPLE_EN******/

/******LOAD_STORE_RN_DATA******/
assign load_store_rn_data = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_RN_DATA_START:
`LOAD_STORE_MEMORY_STAGE_RN_DATA_END];
/******LOAD_STORE_RN_DATA******/

/******LOAD_STORE_RD_ADDR******/
assign load_store_rd_addr = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_RD_ADDR_START:
`LOAD_STORE_MEMORY_STAGE_RD_ADDR_END];
/******LOAD_STORE_RD_DATA******/

/******LOAD_STORE_RN_ADDR******/
assign load_store_rn_addr = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_RN_ADDR_START:
`LOAD_STORE_MEMORY_STAGE_RN_ADDR_END];
/******LOAD_STORE_RN_DATA******/

/******LOAD_STORE_INSTR_TAG******/
assign load_store_instr_tag = 
load_store_memory_stage_control_word_in[`LOAD_STORE_MEMORY_STAGE_INSTR_TAG_START:
`LOAD_STORE_MEMORY_STAGE_INSTR_TAG_END];
/******LOAD_STORE_INSTR_TAG******/

data_memory data_cache (
    .rd_out(data_frm_mem_out), 
    .addr_in(addr_to_mem), 
    .we_in(w_en), 
    .wd_in(store_data),  
    .clk_in(clk_in), 
    .swp_ctrl_in(swp_ctrl), 
    .reset_in(reset_in), 
    .ctrl_load_mux_in(ctrl_load_mux), 
    .ctrl_str_mux_in(ctrl_str_mux)
    );

/******LOAD_STORE_MEMORY_STAGE_START******/
register_with_reset #1 reg_load_store_memory_stage_complete (
		 .data_in(load_store_memory_stage_complete), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(load_store_memory_stage_complete_out)
		 );
/******LOAD_STORE_MEMORY_STAGE_START******/

/******LOAD_STORE_MEMORY_STAGE_INSTR_CONFIRMED******/
register_with_reset #1 reg_load_store_instr_confirmed (
		 .data_in(load_store_instr_confirmed), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_memory_stage_instr_confirmed_out)
		 );
/******LOAD_STORE_MEMORY_STAGE_INSTR_CONFIRMED******/

/******LOAD_STORE_MULTIPLE_EN******/
register_with_reset #1 reg_load_store_multiple_en (
		 .data_in(load_store_multiple_en), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_multiple_en_out) 
		 );
/******LOAD_STORE_MULTIPLE_EN******/

/******LOAD_STORE_RN_DATA******/
register_with_reset #32 reg_load_store_rn_data (
		 .data_in(load_store_rn_data), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_rn_data_out)
		 );
/******LOAD_STORE_RN_DATA******/

/******LOAD_STORE_RD_ADDR******/
register_with_reset #4 reg_load_store_rd_addr (
		 .data_in(load_store_rd_addr), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_rd_addr_out)
		 );
/******LOAD_STORE_RD_ADDR******/

/******LOAD_STORE_RN_ADDR******/
register_with_reset #4 reg_load_store_rn_addr (
		 .data_in(load_store_rn_addr), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_rn_addr_out)
		 );
/******LOAD_STORE_RN_ADDR******/

/******LOAD_STORE_INSTR_TAG******/
register_with_reset #4 reg_load_store_instr_tag (
		 .data_in(load_store_instr_tag), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(load_store_memory_stage_complete), 
		 .data_out(load_store_instr_tag_out)
		 );
/******LOAD_STORE_INSTR_TAG******/

endmodule
