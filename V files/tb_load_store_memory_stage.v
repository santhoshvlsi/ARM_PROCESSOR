`include "timescale.v"
`include "load_store_memory_stage_define.v"

module tb_load_store_memory_stage;

	// Inputs
	reg clk_in;
	reg reset_in;
	reg [`LOAD_STORE_MEMORY_STAGE_INSTR_TAG-1:0] instr_tag;
	reg [`LOAD_STORE_MEMORY_STAGE_RD_ADDR-1:0] rd_addr;
	reg [`LOAD_STORE_MEMORY_STAGE_RN_ADDR-1:0] rn_addr;
	reg [`LOAD_STORE_MEMORY_STAGE_RD_DATA-1:0] store_rd_data;
	reg [`LOAD_STORE_MEMORY_STAGE_RN_DATA-1:0] rn_data;
	reg [`LOAD_STORE_MEMORY_STAGE_ADDRESS-1:0] mem_addr;
	reg swp_ctrl,instr_confirmed,load_store_multiple_en,memory_stage_start;
	reg [`LOAD_STORE_MEMORY_STAGE_CTRL_LOAD_MUX-1:0] ctrl_load_mux;
	reg [`LOAD_STORE_MEMORY_STAGE_CTRL_STR_MUX-1:0] ctrl_str_mux;
	reg [`LOAD_STORE_MEMORY_STAGE_W_EN-1:0] w_en;

	// Outputs
	wire [`LOAD_STORE_MEMORY_STAGE_RD_DATA-1:0] data_frm_mem_out;
	wire load_store_multiple_en_out;
	wire load_store_memory_stage_complete_out;
	wire load_store_memory_stage_instr_confirmed_out;
	wire [`LOAD_STORE_MEMORY_STAGE_RN_DATA-1:0] load_store_rn_data_out;
	wire [`LOAD_STORE_MEMORY_STAGE_RD_ADDR-1:0] load_store_rd_addr_out;
	wire [`LOAD_STORE_MEMORY_STAGE_RN_ADDR-1:0] load_store_rn_addr_out;
	wire [`LOAD_STORE_MEMORY_STAGE_INSTR_TAG-1:0] load_store_instr_tag_out;
	
	// Instantiate the Unit Under Test (UUT)
	load_store_memory_stage uut (
		.clk_in(clk_in), 
		.reset_in(reset_in), 
		.load_store_memory_stage_control_word_in({instr_tag,rd_addr,rn_addr,store_rd_data,rn_data,
		mem_addr,swp_ctrl,ctrl_load_mux,ctrl_str_mux,w_en,instr_confirmed,load_store_multiple_en,
		memory_stage_start}), 
		.data_frm_mem_out(data_frm_mem_out), 
		.load_store_multiple_en_out(load_store_multiple_en_out), 
		.load_store_memory_stage_complete_out(load_store_memory_stage_complete_out), 
		.load_store_memory_stage_instr_confirmed_out(load_store_memory_stage_instr_confirmed_out), 
		.load_store_rn_data_out(load_store_rn_data_out), 
		.load_store_rd_addr_out(load_store_rd_addr_out), 
		.load_store_rn_addr_out(load_store_rn_addr_out), 
		.load_store_instr_tag_out(load_store_instr_tag_out)
	);

	initial begin
		// Initialize Inputs
		clk_in <= 0;
		reset_in <= 1;
		instr_tag <= 0;
		rd_addr <= 0;
		rn_addr <= 0;
		store_rd_data <= 0;
		rn_data <= 0;
		mem_addr <= 0;
		swp_ctrl <= 0;
		instr_confirmed <= 0;
		load_store_multiple_en <= 0;
		memory_stage_start <= 0;
		ctrl_load_mux <= 0;
		ctrl_str_mux <= 0;
		w_en <= 0;
		
		#105;
		reset_in <= 1'b0;
		#10;
		instr_tag <= 0;
		rd_addr <= 1;
		rn_addr <= 2;
		store_rd_data <= 3;
		rn_data <= 5;
		mem_addr <= 6;
		swp_ctrl <= 0;
		instr_confirmed <= 1;
		load_store_multiple_en <= 0;
		memory_stage_start <= 1;
		ctrl_load_mux <= 1;
		ctrl_str_mux <= 0;
		w_en <= 0;
		#10;
		instr_tag <= 1;
		rd_addr <= 2;
		rn_addr <= 3;
		store_rd_data <= 4;
		rn_data <= 6;
		mem_addr <= 7;
		swp_ctrl <= 0;
		instr_confirmed <= 0;
		load_store_multiple_en <= 1;
		memory_stage_start <= 1;
		ctrl_load_mux <= 1;
		ctrl_str_mux <= 1;
		w_en <= 15;
		#10;
		instr_tag <= 1;
		rd_addr <= 2;
		rn_addr <= 3;
		store_rd_data <= 4;
		rn_data <= 6;
		mem_addr <= 7;
		swp_ctrl <= 0;
		instr_confirmed <= 0;
		load_store_multiple_en <= 1;
		memory_stage_start <= 0;
		ctrl_load_mux <= 1;
		ctrl_str_mux <= 1;
		w_en <= 15;
		
		// Add stimulus here

	end
   
	always #5 clk_in = ~clk_in;
	
endmodule

