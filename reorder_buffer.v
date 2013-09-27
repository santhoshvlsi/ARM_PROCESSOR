`include "timescale.v"
`include "reorder_buffer_define.v"

module reorder_buffer(
							input clk_in,
							input reset_in,
							/******NEW_ENTRY_DATA******/
							input [`RB_NEW_ENTRY_WORD_SIZE-1:0] new_entry_word1_in,
							input [`RB_NEW_ENTRY_WORD_SIZE-1:0] new_entry_word2_in,
							input reorder_buffer_update_in,
							/******NEW_ENTRY_DATA******/
							
							/******REG_DATA_FROM_PIPES******/
							input [127:0] rd_data_pipes_in,
							input [127:0] rn_data_pipes_in,
							input [127:0] cpsr_data_pipes_in,
							/******REG_DATA_FROM_PIPES******/
							
							/******TAG_BITS_PIPES******/
							input [`TAG_BITS_ALL_PIPES_COMBINED-1:0] tag_bits_pipes_combined_in,
							/******TAG_BITS_PIPES******/
							
							/******REG_ADDR_PIPES_COMBINED******/
							input [`REG_ADDR_PIPES_COMBINED-1:0] rd_addr_pipes_combined_in,
							input [`REG_ADDR_PIPES_COMBINED-1:0] rn_addr_pipes_combined_in,
							/******REG_ADDR_PIPES_COMBINED******/
							
							/******INSTR_COMPLETE_PIPES******/
							input [3:0] instr_complete_frm_pipes_in,
							/******INSTR_COMPLETE_PIPES******/
							
							/******SPECULATIVE_RESULT******/
							input [3:0] speculative_result_in,
							/******SPECULATIVE_RESULT******/
							
							/******TAG_BITS_TO_ISSUE_TO_PIPES******/
							input [`TAG_RD_ISSUE-1:0] tag_bits_for_rd_to_issue_in,
							input [`RD_ADDR_ISSUE-1:0] rd_addr_to_issue_in,
							input [`RD_DATA_PIPES-1:0] rd_data_issue_pipes_frm_reg_file_in,
							input [`TAG_RN_ISSUE-1:0] tag_bits_for_rn_to_issue_in,
							input [`RN_ADDR_ISSUE-1:0] rn_addr_to_issue_in,
							input [`RN_DATA_PIPES-1:0] rn_data_issue_pipes_frm_reg_file_in,
							input [`TAG_RM_ISSUE-1:0] tag_bits_for_rm_to_issue_in,
							input [`RM_ADDR_ISSUE-1:0] rm_addr_to_issue_in,
							input [`RM_DATA_PIPES-1:0] rm_data_issue_pipes_frm_reg_file_in,
							input [`TAG_RS_ISSUE-1:0] tag_bits_for_rs_to_issue_in,
							input [`RS_ADDR_ISSUE-1:0] rs_addr_to_issue_in,
							input [`RS_DATA_PIPES-1:0] rs_data_issue_pipes_frm_reg_file_in,
							input [`TAG_CPSR_ISSUE-1:0] tag_bits_for_cpsr_to_issue_in,
							input [31:0] cpsr_data_issue_pipes_frm_reg_file_in,
							/******TAG_BITS_TO_ISSUE_TO_PIPES******/
							
							/******ldm_stall_in******/
							input ldm_stall_in,
							input reg_update_ldm_stm_in,
							/******ldm_stall_in******/ 
							
							output [`TAG_BITS_SIZE-1:0] reorder_buffer_status_out,
							
							/******DATA_TO_ISSUE_PIPES******/
							output [`RD_DATA_PIPES-1:0] rd_data_to_pipes_out,
							output [`RN_DATA_PIPES-1:0] rn_data_to_issue_pipes_out,
							output [`RM_DATA_PIPES-1:0] rm_data_to_issue_pipes_out,
							output [`RS_DATA_PIPES-1:0] rs_data_to_issue_pipes_out,
							output [`CPSR_DATA_PIPES-1:0] cpsr_data_to_issue_pipes_out,
							/******DATA_TO_ISSUE_PIPES******/
							
							/******TAG_RETIRE******/
							output [3:0] tag_retire_pipes_for_rd_out,
							output [3:0] tag_retire_pipes_for_rn_out,
							output [3:0] tag_retire_pipes_for_cpsr_out,
							/******TAG_RETIRE******/
							
							/******TAG_CHANGE******/
							output [3:0] tag_change_pipes_for_rd_out,
							output [3:0] tag_change_pipes_for_rn_out,
							output [3:0] tag_change_pipes_for_cpsr_out,
							output [`TAG_BITS_ALL_PIPES_COMBINED-1:0] tag_to_change_specu_for_rd_out,
							output [`TAG_BITS_ALL_PIPES_COMBINED-1:0] tag_to_change_specu_for_rn_out,
							output [`TAG_BITS_ALL_PIPES_COMBINED-1:0] tag_to_change_specu_for_cpsr_out,
							/******TAG_CHANGE******/
							
							/******DATA_RETIRE******/
							output [`DATA_RETIRE-1:0] data_retire_out, 
							output [`RETIRE_WRITE_PORTS-1:0] data_retire_write_en_out  
							
							
    );

wire [`RB_NEW_ENTRY_WORD_SIZE-1:0] new_entry_data [`REORDER_BUFFER_SIZE-1:0];
wire [`RB_NEW_ENTRY_WORD_SIZE-1:0] data_to_reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`RB_NEW_ENTRY_WORD_SIZE-1:0] reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`TAG_BITS_SIZE-1:0] reorder_buffer_status;
wire [`REORDER_BUFFER_SIZE-1:0] mux_sel_bit_vector1,mux_sel_bit_vector2,mux_sel_bit_vector;
wire [`REORDER_BUFFER_SIZE-1:0] reorder_buffer_position_occupied;
wire [`REORDER_BUFFER_SIZE-1:0] en_bits_new_entry;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_with_alu_pipe1,tag_matched_with_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_with_load_store_pipe3,tag_matched_with_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_with_alu_pipe1_final,tag_matched_with_alu_pipe2_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_with_load_store_pipe3_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_with_branch_pipe4_final,tag_matched_combined_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_alu_pipe1_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_alu_pipe2_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_load_store_pipe3_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_branch_pipe4_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_matched_for_instr_complete_combined_final;
wire [1:0] data_frm_reg_mux_sel [`REORDER_BUFFER_SIZE-1:0];
wire [1:0] data_frm_instr_complete_mux_sel [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] rd_data [`REORDER_BUFFER_SIZE-1:0],rn_data [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] cpsr_data [`REORDER_BUFFER_SIZE-1:0];
wire [`REORDER_BUFFER_SIZE-1:0] instr_complete_data;
wire [`REORDER_BUFFER_SIZE-1:0] speculative_instr_data;
wire [31:0] data_to_rd [`REORDER_BUFFER_SIZE-1:0],data_to_rn [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_cpsr [`REORDER_BUFFER_SIZE-1:0];
wire [`REORDER_BUFFER_SIZE-1:0] data_to_speculative_instr;
wire [31:0] data_to_rd_mux_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_rn_mux_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_cpsr_mux_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_rd_mux_shift [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_rn_mux_shift [`REORDER_BUFFER_SIZE-1:0];
wire [31:0] data_to_cpsr_mux_shift [`REORDER_BUFFER_SIZE-1:0];
wire  [`REORDER_BUFFER_SIZE-1:0] data_to_instr_complete;
wire [`REORDER_BUFFER_SIZE-1:0] data_to_instr_complete_mux_pipes;
wire [`REORDER_BUFFER_SIZE-1:0] data_to_instr_complete_mux_shift;
wire [`REORDER_BUFFER_SIZE-1:0] rd_reg_en,rn_reg_en,cpsr_reg_en,instr_complete_reg_en;
wire [`REORDER_BUFFER_SIZE-1:0] speculative_instr_en;
wire [`REORDER_BUFFER_SIZE-1:0] rd_update_by_pipes,rn_update_by_pipes,cpsr_update_by_pipes;
wire [`REORDER_BUFFER_SIZE-1:0] rd_update_by_pipes_final,rn_update_by_pipes_final;
wire [`REORDER_BUFFER_SIZE-1:0] cpsr_update_by_pipes_final;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rd_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rd_addr_issue_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rn_match_alu_pipe1,tag_issue_rn_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rn_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_issue_match_alu_pipe1,rn_addr_issue_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_with_ldm_buffer_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_with_ldm_buffer_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_with_ldm_buffer_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_match_with_ldm_buffer_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_match_with_ldm_buffer_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_match_with_ldm_buffer_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_match_with_ldm_buffer_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] rs_addr_match_with_ldm_buffer_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] rs_addr_match_with_ldm_buffer_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rs_addr_match_with_ldm_buffer_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_issue_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rm_match_alu_pipe1,tag_issue_rm_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rm_match_load_store_pipe3,tag_issue_rm_match_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_issue_match_alu_pipe1,rm_addr_issue_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rm_addr_issue_match_load_store_pipe3,rm_addr_issue_match_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rs_match_alu_pipe1,tag_issue_rs_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_rs_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rs_addr_issue_match_alu_pipe1,rs_addr_issue_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rs_addr_issue_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_cpsr_match_alu_pipe1,tag_issue_cpsr_match_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_cpsr_match_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_issue_cpsr_match_branch_pipe4;
wire [`RD_DATA_PIPES-1:0] rd_data_issue_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [`RD_DATA_PIPES-1:0] rd_data_issue_frm_reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`RN_DATA_PIPES-1:0] rn_data_issue_frm_reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`RM_DATA_PIPES-1:0] rm_data_issue_frm_reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`RS_DATA_PIPES-1:0] rs_data_issue_frm_reorder_buffer [`REORDER_BUFFER_SIZE-1:0];
wire [`RN_DATA_PIPES-1:0] rn_data_issue_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [`RM_DATA_PIPES-1:0] rm_data_issue_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [`RS_DATA_PIPES-1:0] rs_data_issue_pipes [`REORDER_BUFFER_SIZE-1:0];
wire [`RD_DATA_PIPES-1:0] rd_data_to_pipes;
wire [`RN_DATA_PIPES-1:0] rn_data_to_issue_pipes;
wire [`RM_DATA_PIPES-1:0] rm_data_to_issue_pipes;
wire [`RS_DATA_PIPES-1:0] rs_data_to_issue_pipes;
wire [`CPSR_DATA_PIPES-1:0] cpsr_data_to_issue_pipes;
wire [`REORDER_BUFFER_SIZE-1:0] speculative_instr,speculative_instr_final;
wire [`REORDER_BUFFER_SIZE-1:0] data_to_speculative_instr_pipes;
wire [`REORDER_BUFFER_SIZE-1:0] data_to_speculative_instr_shift;
wire [`REORDER_BUFFER_SIZE-1:0] tag_retire_pipes_rd [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_retire_pipes_rn [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_retire_pipes_cpsr [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_pipes_rd [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_pipes_rn [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_pipes_cpsr [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_pipes [3:0];
wire [`REORDER_BUFFER_SIZE-1:0] rd_addr_match_for_tag_change_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] rd_addr_match_for_tag_change_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rd_addr_match_for_tag_change_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rd_addr_match_for_tag_change_specu_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_for_tag_change_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_for_tag_change_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_for_tag_change_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] rn_addr_match_for_tag_change_specu_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_specu_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rd_final_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rn_final_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_cpsr_final_specu_alu_pipe1;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rd_final_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rn_final_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_cpsr_final_specu_alu_pipe2;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rd_final_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rn_final_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_cpsr_final_specu_load_store_pipe3;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rd_final_specu_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_rn_final_specu_branch_pipe4;
wire [`REORDER_BUFFER_SIZE-1:0] tag_change_selector_for_cpsr_final_specu_branch_pipe4;
wire new_tag_instr_complete_for_rd_alu_pipe1,new_tag_instr_complete_for_rd_alu_pipe2;
wire new_tag_instr_complete_for_rd_load_store_pipe3,new_tag_instr_complete_for_rd_branch_pipe4;
wire new_tag_instr_complete_for_rn_alu_pipe1,new_tag_instr_complete_for_rn_alu_pipe2;
wire new_tag_instr_complete_for_rn_load_store_pipe3,new_tag_instr_complete_for_rn_branch_pipe4;
wire new_tag_instr_complete_for_cpsr_alu_pipe1,new_tag_instr_complete_for_cpsr_alu_pipe2;
wire new_tag_instr_complete_for_cpsr_load_store_pipe3,new_tag_instr_complete_for_cpsr_branch_pipe4;
wire new_tag_speculative_instr_for_rd_alu_pipe1,new_tag_speculative_instr_for_rd_alu_pipe2;
wire new_tag_speculative_instr_for_rd_load_store_pipe3,new_tag_speculative_instr_for_rd_branch_pipe4;
wire new_tag_speculative_instr_for_rn_alu_pipe1,new_tag_speculative_instr_for_rn_alu_pipe2;
wire new_tag_speculative_instr_for_rn_load_store_pipe3,new_tag_speculative_instr_for_rn_branch_pipe4;
wire new_tag_speculative_instr_for_cpsr_alu_pipe1,new_tag_speculative_instr_for_cpsr_alu_pipe2;
wire new_tag_speculative_instr_for_cpsr_load_store_pipe3,new_tag_speculative_instr_for_cpsr_branch_pipe4;
wire new_tag_speculative_result_for_rd_alu_pipe1,new_tag_speculative_result_for_rd_alu_pipe2;
wire new_tag_speculative_result_for_rd_load_store_pipe3,new_tag_speculative_result_for_rd_branch_pipe4;
wire new_tag_speculative_result_for_rn_alu_pipe1,new_tag_speculative_result_for_rn_alu_pipe2;
wire new_tag_speculative_result_for_rn_load_store_pipe3,new_tag_speculative_result_for_rn_branch_pipe4;
wire new_tag_speculative_result_for_cpsr_alu_pipe1,new_tag_speculative_result_for_cpsr_alu_pipe2;
wire new_tag_speculative_result_for_cpsr_load_store_pipe3;
wire new_tag_speculative_result_for_cpsr_branch_pipe4;
wire [`LDM_STM_REG_SIZE-1:0] ldm_stm_data_en; 
wire [`LDM_STM_REG_SIZE-2:0] ldm_stm_data_en_temp;
wire [`LDM_STM_REG_SIZE-1:0] en_reg_ldm_stm_data_en;
wire [`LDM_STM_DATA_SIZE-1:0] ldm_stm_data[`LDM_STM_REG_SIZE-1:0];
wire [`LDM_STM_DATA_SIZE-1:0] data_to_ldm_stm_data [`LDM_STM_REG_SIZE-1:0];
wire ldm_stm_retire,ldm_stm_retire_all_16,ldm_stm_retire_not_all_16;
wire [`LDM_STM_REG_SIZE-1:0] rd_addr_match_with_ldm_buffer;
wire [3:0] rd_data_ldm_buffer_selector,rn_data_ldm_buffer_selector_alu_pipe1;
wire [3:0] rn_data_ldm_buffer_selector_alu_pipe2,rn_data_ldm_buffer_selector_load_store_pipe3;
wire [3:0] rm_data_ldm_buffer_selector_alu_pipe1,rm_data_ldm_buffer_selector_alu_pipe2;
wire [3:0] rm_data_ldm_buffer_selector_load_store_pipe3,rm_data_ldm_buffer_selector_branch_pipe4;
wire [3:0] rs_data_ldm_buffer_selector_alu_pipe1,rs_data_ldm_buffer_selector_alu_pipe2;
wire [3:0] rs_data_ldm_buffer_selector_load_store_pipe3;
wire [31:0] rd_data_frm_ldm_buffer;
wire [`RN_DATA_PIPES-1:0] rn_data_frm_ldm_buffer;
wire [`RM_DATA_PIPES-1:0] rm_data_frm_ldm_buffer;
wire [`RS_DATA_PIPES-1:0] rs_data_frm_ldm_buffer;
wire reorder_buffer_shift,reorder_buffer_shift_2;


reorder_buffer_counter counter_reorder_buffer (.clk_in(clk_in),
															  .reset_in(reset_in),
															  .reorder_buffer_shift_in(reorder_buffer_shift),
															  .reorder_buffer_update_in(reorder_buffer_update_in),
															  .reorder_buffer_shift_2_in(reorder_buffer_shift_2),
															  .reorder_buffer_status_out(reorder_buffer_status_out));

/*************************************NEW_ENTRY_DATA_STARTS******************************************/

assign reorder_buffer_status = reorder_buffer_shift_2 ? (reorder_buffer_status_out - 2) : 
(reorder_buffer_shift ? (reorder_buffer_status_out - 1) : reorder_buffer_status_out);

mux16 #`REORDER_BUFFER_SIZE bit_vector1_sel_mux (
    .y_out(mux_sel_bit_vector1), 
    .i0_in(`REORDER_BUFFER_SIZE'd1), 
    .i1_in(`REORDER_BUFFER_SIZE'd2), 
    .i2_in(`REORDER_BUFFER_SIZE'd4), 
    .i3_in(`REORDER_BUFFER_SIZE'd8), 
    .i4_in(`REORDER_BUFFER_SIZE'd16), 
    .i5_in(`REORDER_BUFFER_SIZE'd32), 
    .i6_in(`REORDER_BUFFER_SIZE'd64), 
    .i7_in(`REORDER_BUFFER_SIZE'd128), 
    .i8_in(`REORDER_BUFFER_SIZE'd256), 
    .i9_in(`REORDER_BUFFER_SIZE'd512), 
    .i10_in(`REORDER_BUFFER_SIZE'd1024), 
    .i11_in(`REORDER_BUFFER_SIZE'd2048), 
    .i12_in(`REORDER_BUFFER_SIZE'd4096), 
    .i13_in(`REORDER_BUFFER_SIZE'd8192), 
    .i14_in(`REORDER_BUFFER_SIZE'd16384), 
    .i15_in(`REORDER_BUFFER_SIZE'd32768), 
    .sel_in(reorder_buffer_status)
    );

mux16 #`REORDER_BUFFER_SIZE bit_vector2_sel_mux (
    .y_out(mux_sel_bit_vector2), 
    .i0_in(`REORDER_BUFFER_SIZE'd2), 
    .i1_in(`REORDER_BUFFER_SIZE'd4), 
    .i2_in(`REORDER_BUFFER_SIZE'd8), 
    .i3_in(`REORDER_BUFFER_SIZE'd16), 
    .i4_in(`REORDER_BUFFER_SIZE'd32), 
    .i5_in(`REORDER_BUFFER_SIZE'd64), 
    .i6_in(`REORDER_BUFFER_SIZE'd128), 
    .i7_in(`REORDER_BUFFER_SIZE'd256), 
    .i8_in(`REORDER_BUFFER_SIZE'd512), 
    .i9_in(`REORDER_BUFFER_SIZE'd1024), 
    .i10_in(`REORDER_BUFFER_SIZE'd2048), 
    .i11_in(`REORDER_BUFFER_SIZE'd4096), 
    .i12_in(`REORDER_BUFFER_SIZE'd8192), 
    .i13_in(`REORDER_BUFFER_SIZE'd16384), 
    .i14_in(`REORDER_BUFFER_SIZE'd32768), 
    //.i15_in(`REORDER_BUFFER_SIZE'd65536),  
	 .i15_in(`REORDER_BUFFER_SIZE'd0),  
    .sel_in(reorder_buffer_status)
    );
	 
mux16 #`REORDER_BUFFER_SIZE instr_complete_mux (
    .y_out(reorder_buffer_position_occupied), 
    .i0_in(`REORDER_BUFFER_SIZE'd0), 
	 .i1_in(`REORDER_BUFFER_SIZE'd1),
    .i2_in(`REORDER_BUFFER_SIZE'd3), 
    .i3_in(`REORDER_BUFFER_SIZE'd7), 
    .i4_in(`REORDER_BUFFER_SIZE'd15), 
    .i5_in(`REORDER_BUFFER_SIZE'd31), 
    .i6_in(`REORDER_BUFFER_SIZE'd63), 
    .i7_in(`REORDER_BUFFER_SIZE'd127), 
    .i8_in(`REORDER_BUFFER_SIZE'd255), 
    .i9_in(`REORDER_BUFFER_SIZE'd511), 
    .i10_in(`REORDER_BUFFER_SIZE'd1023), 
    .i11_in(`REORDER_BUFFER_SIZE'd2047), 
    .i12_in(`REORDER_BUFFER_SIZE'd4095), 
    .i13_in(`REORDER_BUFFER_SIZE'd8191), 
    .i14_in(`REORDER_BUFFER_SIZE'd16382), 
    .i15_in(`REORDER_BUFFER_SIZE'd32767), 
    .sel_in(reorder_buffer_status_out)
    );
															  
genvar i;
generate 
for(i=0;i<=`REORDER_BUFFER_SIZE-1;i=i+1)
begin : grp_new_entry_data
	assign new_entry_data[i] = ({`RB_NEW_ENTRY_WORD_SIZE{mux_sel_bit_vector1[i]}} & 
	new_entry_word1_in) | ({`RB_NEW_ENTRY_WORD_SIZE{mux_sel_bit_vector2[i]}} & new_entry_word2_in);
end
endgenerate

assign mux_sel_bit_vector = mux_sel_bit_vector1 | mux_sel_bit_vector2;

genvar j;
generate 
for(j=0;j<=`REORDER_BUFFER_SIZE-3;j=j+1)
begin : grp_data_to_reorder_buffer
	assign data_to_reorder_buffer[j] = ((mux_sel_bit_vector[j] & reorder_buffer_update_in) ? 
	new_entry_data[j] : (reorder_buffer_shift_2 ? reorder_buffer[j+2] : reorder_buffer[j+1]));
end
endgenerate

assign data_to_reorder_buffer[`REORDER_BUFFER_SIZE-2] = ((mux_sel_bit_vector[`REORDER_BUFFER_SIZE-2] & 
reorder_buffer_update_in) ? new_entry_data[`REORDER_BUFFER_SIZE-2] : 
reorder_buffer[`REORDER_BUFFER_SIZE-1]);
assign data_to_reorder_buffer[`REORDER_BUFFER_SIZE-1] = new_entry_data[`REORDER_BUFFER_SIZE-1];

genvar k;
generate 
for(k=0;k<=`REORDER_BUFFER_SIZE-1;k=k+1)
begin : grp_reorder_buffer
	register_with_reset #`RB_NEW_ENTRY_WORD_SIZE reg_reorder_buffer (
		 .data_in(data_to_reorder_buffer[k]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(en_bits_new_entry[k]), 
		 .data_out(reorder_buffer[k])
		 );
end
endgenerate

genvar l;
generate 
for(l=0;l<=`REORDER_BUFFER_SIZE-1;l=l+1)
begin : grp_en_bits_new_entry
	assign en_bits_new_entry[l] = reorder_buffer_shift | reorder_buffer_shift_2 | 
	(reorder_buffer_update_in & mux_sel_bit_vector[l]);
end
endgenerate

/*************************************NEW_ENTRY_DATA_ENDS******************************************/

/*************************************TAG_MATCH_STARTS******************************************/
genvar m;
generate 
for(m=0;m<=`REORDER_BUFFER_SIZE-1;m=m+1)
begin : grp_tag_matched
	assign tag_matched_for_instr_complete_alu_pipe1[m] = 
	~(|(tag_bits_pipes_combined_in[`TAG_BITS_ALU_PIPE1_STARTS:`TAG_BITS_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[m][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[m];
	assign tag_matched_with_alu_pipe1[m] = tag_matched_for_instr_complete_alu_pipe1[m] & 
	instr_complete_frm_pipes_in[3];
		
	assign tag_matched_for_instr_complete_alu_pipe2[m] = 
	~(|(tag_bits_pipes_combined_in[`TAG_BITS_ALU_PIPE2_STARTS:`TAG_BITS_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[m][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[m];
	assign tag_matched_with_alu_pipe2[m] = tag_matched_for_instr_complete_alu_pipe2[m] & 
	instr_complete_frm_pipes_in[2];
		
	assign tag_matched_for_instr_complete_load_store_pipe3[m] = 
	~(|(tag_bits_pipes_combined_in[`TAG_BITS_LOAD_STORE_PIPE3_STARTS:`TAG_BITS_LOAD_STORE_PIPE3_ENDS] ^ 
	reorder_buffer[m][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[m];
	assign tag_matched_with_load_store_pipe3[m] = tag_matched_for_instr_complete_load_store_pipe3[m] & 
	instr_complete_frm_pipes_in[1];
		
	assign tag_matched_for_instr_complete_branch_pipe4[m] = 
	~(|(tag_bits_pipes_combined_in[`TAG_BITS_BRANCH_PIPE4_STARTS:`TAG_BITS_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[m][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[m];
	assign tag_matched_with_branch_pipe4[m] = tag_matched_for_instr_complete_branch_pipe4[m] & 
	instr_complete_frm_pipes_in[0];
	
	assign rd_update_by_pipes[m] = reorder_buffer[m][`RB_RD_UPDATE];
	assign rn_update_by_pipes[m] = reorder_buffer[m][`RB_RN_UPDATE];
	assign cpsr_update_by_pipes[m] = reorder_buffer[m][`RB_CPSR_UPDATE];
	assign speculative_instr[m] = reorder_buffer[m][`RB_CPSR_SPECULATIVE_INSTR];
	
	/******TAG_RETIRE_STARTS******/
	/******RD_STARTS******/
	assign tag_retire_pipes_rd[3][m] = (tag_matched_with_alu_pipe1[m] & (~speculative_instr[m] | 
	speculative_result_in[3])) & rd_update_by_pipes[m];
	assign tag_retire_pipes_rd[2][m] = (tag_matched_with_alu_pipe2[m] & (~speculative_instr[m] | 
	speculative_result_in[2])) & rd_update_by_pipes[m];
	assign tag_retire_pipes_rd[1][m] = (tag_matched_with_load_store_pipe3[m] & (~speculative_instr[m] | 
	speculative_result_in[1])) & rd_update_by_pipes[m];
	assign tag_retire_pipes_rd[0][m] = (tag_matched_with_branch_pipe4[m] & (~speculative_instr[m] | 
	speculative_result_in[0])) & rd_update_by_pipes[m];
	/******RD_ENDS******/
	/******RN_STARTS******/
	assign tag_retire_pipes_rn[3][m] = (tag_matched_with_alu_pipe1[m] & (~speculative_instr[m] | 
	speculative_result_in[3])) & rn_update_by_pipes[m];
	assign tag_retire_pipes_rn[2][m] = (tag_matched_with_alu_pipe2[m] & (~speculative_instr[m] | 
	speculative_result_in[2])) & rn_update_by_pipes[m];
	assign tag_retire_pipes_rn[1][m] = (tag_matched_with_load_store_pipe3[m] & (~speculative_instr[m] | 
	speculative_result_in[1])) & rn_update_by_pipes[m];
	assign tag_retire_pipes_rn[0][m] = (tag_matched_with_branch_pipe4[m] & (~speculative_instr[m] | 
	speculative_result_in[0])) & rn_update_by_pipes[m];
	/******RN_ENDS******/
	/******RN_STARTS******/
	assign tag_retire_pipes_cpsr[3][m] = (tag_matched_with_alu_pipe1[m] & (~speculative_instr[m] | 
	speculative_result_in[3])) & cpsr_update_by_pipes[m];
	assign tag_retire_pipes_cpsr[2][m] = (tag_matched_with_alu_pipe2[m] & (~speculative_instr[m] | 
	speculative_result_in[2])) & cpsr_update_by_pipes[m];
	assign tag_retire_pipes_cpsr[1][m] = (tag_matched_with_load_store_pipe3[m] & (~speculative_instr[m] | 
	speculative_result_in[1])) & cpsr_update_by_pipes[m];
	assign tag_retire_pipes_cpsr[0][m] = (tag_matched_with_branch_pipe4[m] & (~speculative_instr[m] | 
	speculative_result_in[0])) & cpsr_update_by_pipes[m];
	/******RN_ENDS******/
	/******TAG_RETIRE_ENDS******/
	
	/******TAG_CHANGE_STARTS******/
	assign tag_change_pipes[3][m] = (tag_matched_with_alu_pipe1[m] & speculative_instr[m] & 
	~speculative_result_in[3]);
	assign tag_change_pipes[2][m] = (tag_matched_with_alu_pipe2[m] & speculative_instr[m] & 
	~speculative_result_in[2]);
	assign tag_change_pipes[1][m] = (tag_matched_with_load_store_pipe3[m] & speculative_instr[m] & 
	~speculative_result_in[1]);
	assign tag_change_pipes[0][m] = (tag_matched_with_branch_pipe4[m] & speculative_instr[m] & 
	~speculative_result_in[0]);
	/******RD_STARTS******/
	assign tag_change_pipes_rd[3][m] = tag_change_pipes[3][m] & rd_update_by_pipes[m];
	assign tag_change_pipes_rd[2][m] = tag_change_pipes[2][m] & rd_update_by_pipes[m];
	assign tag_change_pipes_rd[1][m] = tag_change_pipes[1][m] & rd_update_by_pipes[m];
	assign tag_change_pipes_rd[0][m] = tag_change_pipes[0][m] & rd_update_by_pipes[m];
	/******RD_ENDS******/
	/******RN_STARTS******/
	assign tag_change_pipes_rn[3][m] = tag_change_pipes[3][m] & rn_update_by_pipes[m];
	assign tag_change_pipes_rn[2][m] = tag_change_pipes[2][m] & rn_update_by_pipes[m];
	assign tag_change_pipes_rn[1][m] = tag_change_pipes[1][m] & rn_update_by_pipes[m];
	assign tag_change_pipes_rn[0][m] = tag_change_pipes[0][m] & rn_update_by_pipes[m];
	/******RN_ENDS******/
	/******CPSR_STARTS******/
	assign tag_change_pipes_cpsr[3][m] = tag_change_pipes[3][m] & cpsr_update_by_pipes[m];
	assign tag_change_pipes_cpsr[2][m] = tag_change_pipes[2][m] & cpsr_update_by_pipes[m];
	assign tag_change_pipes_cpsr[1][m] = tag_change_pipes[1][m] & cpsr_update_by_pipes[m];
	assign tag_change_pipes_cpsr[0][m] = tag_change_pipes[0][m] & cpsr_update_by_pipes[m];
	/******CPSR_ENDS******/
	/******TAG_CHANGE_ENDS******/
	
end
endgenerate
/*************************************TAG_MATCH_ENDS******************************************/

/*************************************TAG_MATCH_FINAL_STARTS******************************************/
assign tag_matched_for_instr_complete_alu_pipe1_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_for_instr_complete_alu_pipe1[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_for_instr_complete_alu_pipe1[`REORDER_BUFFER_SIZE-1:1]} : 
tag_matched_for_instr_complete_alu_pipe1);

assign tag_matched_with_alu_pipe1_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_with_alu_pipe1[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_with_alu_pipe1[`REORDER_BUFFER_SIZE-1:1]} : tag_matched_with_alu_pipe1);


assign tag_matched_for_instr_complete_alu_pipe2_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_for_instr_complete_alu_pipe2[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_for_instr_complete_alu_pipe2[`REORDER_BUFFER_SIZE-1:1]} : 
tag_matched_for_instr_complete_alu_pipe2);

assign tag_matched_with_alu_pipe2_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_with_alu_pipe2[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_with_alu_pipe2[`REORDER_BUFFER_SIZE-1:1]} : tag_matched_with_alu_pipe2);


assign tag_matched_for_instr_complete_load_store_pipe3_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_for_instr_complete_load_store_pipe3[`REORDER_BUFFER_SIZE-1:2]} : 
(reorder_buffer_shift ? 
{1'b0,tag_matched_for_instr_complete_load_store_pipe3[`REORDER_BUFFER_SIZE-1:1]} : 
tag_matched_for_instr_complete_load_store_pipe3);

assign tag_matched_with_load_store_pipe3_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_with_load_store_pipe3[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_with_load_store_pipe3[`REORDER_BUFFER_SIZE-1:1]} : 
tag_matched_with_load_store_pipe3);


assign tag_matched_for_instr_complete_branch_pipe4_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_for_instr_complete_branch_pipe4[`REORDER_BUFFER_SIZE-1:2]} : 
(reorder_buffer_shift ? {1'b0,tag_matched_for_instr_complete_branch_pipe4[`REORDER_BUFFER_SIZE-1:1]}
: tag_matched_for_instr_complete_branch_pipe4);

assign tag_matched_with_branch_pipe4_final = reorder_buffer_shift_2 ? 
{2'b00,tag_matched_with_branch_pipe4[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,tag_matched_with_branch_pipe4[`REORDER_BUFFER_SIZE-1:1]} : tag_matched_with_branch_pipe4);


assign rd_update_by_pipes_final = reorder_buffer_shift_2 ? 
{2'b00,rd_update_by_pipes[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,rd_update_by_pipes[`REORDER_BUFFER_SIZE-1:1]} : rd_update_by_pipes);

assign rn_update_by_pipes_final = reorder_buffer_shift_2 ? 
{2'b00,rn_update_by_pipes[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,rn_update_by_pipes[`REORDER_BUFFER_SIZE-1:1]} : rn_update_by_pipes);

assign cpsr_update_by_pipes_final = reorder_buffer_shift_2 ? 
{2'b00,cpsr_update_by_pipes[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,cpsr_update_by_pipes[`REORDER_BUFFER_SIZE-1:1]} : cpsr_update_by_pipes);

assign speculative_instr_final = reorder_buffer_shift_2 ? 
{2'b00,speculative_instr[`REORDER_BUFFER_SIZE-1:2]} : (reorder_buffer_shift ? 
{1'b0,speculative_instr[`REORDER_BUFFER_SIZE-1:1]} : speculative_instr);

assign tag_matched_for_instr_complete_combined_final = tag_matched_for_instr_complete_alu_pipe1_final |
tag_matched_for_instr_complete_alu_pipe2_final | tag_matched_for_instr_complete_load_store_pipe3_final
| tag_matched_for_instr_complete_branch_pipe4_final;
assign tag_matched_combined_final = tag_matched_with_alu_pipe1_final | tag_matched_with_alu_pipe2_final
| tag_matched_with_load_store_pipe3_final | tag_matched_with_branch_pipe4_final;
/*************************************TAG_MATCH_FINAL_ENDS******************************************/

/*************************************RD_RN_CPSR_DATA_INSTR_COMPLETE_STARTS****************************************/
genvar n;
generate 
for(n=0;n<=`REORDER_BUFFER_SIZE-1;n=n+1)
begin : grp_rd_data_mux_sel
	reg_mux_sel rd_rn_cpsr_mux_sel (
    .tag_matched_with_alu_pipe1_final_in(tag_matched_with_alu_pipe1_final[n]), 
    .tag_matched_with_alu_pipe2_final_in(tag_matched_with_alu_pipe2_final[n]), 
    .tag_matched_with_load_store_pipe3_final_in(tag_matched_with_load_store_pipe3_final[n]), 
    .tag_matched_with_branch_pipe4_final_in(tag_matched_with_branch_pipe4_final[n]), 
    .reg_data_mux_sel_out(data_frm_reg_mux_sel[n])
    );

/******RD_DATA_STARTS******/
	 
	 mux4 #32 rd_mux_pipes (
    .y_out(data_to_rd_mux_pipes[n]), 
    .i0_in(rd_data_pipes_in[127:96]), 
    .i1_in(rd_data_pipes_in[95:64]), 
    .i2_in(rd_data_pipes_in[63:32]), 
    .i3_in(rd_data_pipes_in[31:0]), 
    .sel_in(data_frm_reg_mux_sel[n])
    );
	 
	 assign rd_reg_en[n] = reorder_buffer_shift | reorder_buffer_shift_2 | 
	 (tag_matched_combined_final[n] & rd_update_by_pipes_final[n]);
	 
	 assign data_to_rd[n] = (tag_matched_combined_final[n] & rd_update_by_pipes_final[n]) ? 
	 data_to_rd_mux_pipes[n] : data_to_rd_mux_shift[n];
	 
	 register_with_reset #32 reg_rd_data (
		 .data_in(data_to_rd[n]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(rd_reg_en[n]), 
		 .data_out(rd_data[n])
		 );
/******RD_DATA_ENDS******/	

/******RN_DATA_STARTS******/	 
	mux4 #32 rn_mux_pipes (
    .y_out(data_to_rn_mux_pipes[n]), 
    .i0_in(rn_data_pipes_in[127:96]), 
    .i1_in(rn_data_pipes_in[95:64]), 
    .i2_in(rn_data_pipes_in[63:32]), 
    .i3_in(rn_data_pipes_in[31:0]), 
    .sel_in(data_frm_reg_mux_sel[n])
    );
	 
	assign rn_reg_en[n] = reorder_buffer_shift | reorder_buffer_shift_2 | 
	 (tag_matched_combined_final[n] & rn_update_by_pipes_final[n]);
	 
	assign data_to_rn[n] = (tag_matched_combined_final[n] & rn_update_by_pipes_final[n]) ? 
	 data_to_rn_mux_pipes[n] : data_to_rn_mux_shift[n];
	 
	register_with_reset #32 reg_rn_data (
		 .data_in(data_to_rn[n]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(rn_reg_en[n]), 
		 .data_out(rn_data[n])
		 );

/******RN_DATA_ENDS******/

/******CPSR_DATA_STARTS******/		 
	mux4 #32 cpsr_mux_pipes (
    .y_out(data_to_cpsr_mux_pipes[n]), 
    .i0_in(cpsr_data_pipes_in[127:96]), 
    .i1_in(cpsr_data_pipes_in[95:64]), 
    .i2_in(cpsr_data_pipes_in[63:32]), 
    .i3_in(cpsr_data_pipes_in[31:0]), 
    .sel_in(data_frm_reg_mux_sel[n])
    );
	 
	assign cpsr_reg_en[n] = reorder_buffer_shift | reorder_buffer_shift_2 | 
	 (tag_matched_combined_final[n] & cpsr_update_by_pipes_final[n]);
	 
	assign data_to_cpsr[n] = (tag_matched_combined_final[n] & cpsr_update_by_pipes_final[n]) ? 
	 data_to_cpsr_mux_pipes[n] : data_to_cpsr_mux_shift[n];
	 
	register_with_reset #32 reg_cpsr_data (
		 .data_in(data_to_cpsr[n]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(cpsr_reg_en[n]), 
		 .data_out(cpsr_data[n])
		 );

/******CPSR_DATA_ENDS******/

/******INSTR_COMPLETE_DATA_STARTS******/	
	reg_mux_sel instr_complete_mux_sel (
    .tag_matched_with_alu_pipe1_final_in(tag_matched_for_instr_complete_alu_pipe1_final[n]), 
    .tag_matched_with_alu_pipe2_final_in(tag_matched_for_instr_complete_alu_pipe2_final[n]), 
    .tag_matched_with_load_store_pipe3_final_in(
	 tag_matched_for_instr_complete_load_store_pipe3_final[n]), 
    .tag_matched_with_branch_pipe4_final_in(tag_matched_for_instr_complete_branch_pipe4_final[n]), 
    .reg_data_mux_sel_out(data_frm_instr_complete_mux_sel[n])
    );
	
	mux4 #1 instr_complete_mux_pipes (
    .y_out(data_to_instr_complete_mux_pipes[n]), 
    .i0_in(instr_complete_frm_pipes_in[3]), 
    .i1_in(instr_complete_frm_pipes_in[2]), 
    .i2_in(instr_complete_frm_pipes_in[1]), 
    .i3_in(instr_complete_frm_pipes_in[0]), 
    .sel_in(data_frm_instr_complete_mux_sel[n])
    );
	 
	 assign instr_complete_reg_en[n] = reorder_buffer_shift | reorder_buffer_shift_2 | 
	 tag_matched_for_instr_complete_combined_final[n];
	 
	  assign data_to_instr_complete[n] = tag_matched_for_instr_complete_combined_final[n] ? 
	 data_to_instr_complete_mux_pipes[n] : data_to_instr_complete_mux_shift[n];
	 
	 register_with_reset #1 instr_complete (
		 .data_in(data_to_instr_complete[n]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(instr_complete_reg_en[n]), 
		 .data_out(instr_complete_data[n])
		 );
/******INSTR_COMPLETE_DATA_ENDS******/

/******SPECULATIVE_RESULT_STARTS******/
		mux4 #1 speculative_instr_mux_pipes (
			 .y_out(data_to_speculative_instr_pipes[n]), 
			 .i0_in(speculative_result_in[3]), 
			 .i1_in(speculative_result_in[2]), 
			 .i2_in(speculative_result_in[1]), 
			 .i3_in(speculative_result_in[0]), 
			 .sel_in(data_frm_reg_mux_sel[n])
			 );
			 
		assign speculative_instr_en[n] = reorder_buffer_shift | reorder_buffer_shift_2 | 
		(tag_matched_combined_final[n] & speculative_instr_final[n]);
		
		assign data_to_speculative_instr[n] = (tag_matched_combined_final[n] & 
		speculative_instr_final[n]) ? data_to_speculative_instr_pipes[n] : 
		data_to_speculative_instr_shift[n];
		
		register_with_reset #1 reg_speculative_instr_data (
		 .data_in(data_to_speculative_instr[n]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(speculative_instr_en[n]), 
		 .data_out(speculative_instr_data[n])
		 );
/******SPECULATIVE_RESULT_ENDS******/
end
endgenerate

genvar o;
generate
for(o=0;o<=`REORDER_BUFFER_SIZE-3;o=o+1)
begin : grp_assign_data_to_rd_mux_shift
	assign data_to_rd_mux_shift[o] = reorder_buffer_shift_2 ? rd_data[o+2] : rd_data[o+1];
	assign data_to_rn_mux_shift[o] = reorder_buffer_shift_2 ? rn_data[o+2] : rn_data[o+1];
	assign data_to_cpsr_mux_shift[o] = reorder_buffer_shift_2 ? cpsr_data[o+2] : cpsr_data[o+1];
	assign data_to_instr_complete_mux_shift[o] = reorder_buffer_shift_2 ? instr_complete_data[o+2] : 
	instr_complete_data[o+1];
	assign data_to_speculative_instr_shift[o] = reorder_buffer_shift_2 ? speculative_instr_data[o+2]
	: speculative_instr_data[o+1];
end
assign data_to_rd_mux_shift[`REORDER_BUFFER_SIZE-2] = reorder_buffer_shift_2 ? 32'b0 : 
rd_data[`REORDER_BUFFER_SIZE-1];
assign data_to_rn_mux_shift[`REORDER_BUFFER_SIZE-2] = reorder_buffer_shift_2 ? 32'b0 : 
rn_data[`REORDER_BUFFER_SIZE-1];
assign data_to_cpsr_mux_shift[`REORDER_BUFFER_SIZE-2] = reorder_buffer_shift_2 ? 32'b0 : 
cpsr_data[`REORDER_BUFFER_SIZE-1];
assign data_to_instr_complete_mux_shift[`REORDER_BUFFER_SIZE-2] = reorder_buffer_shift_2 ? 32'b0 : 
instr_complete_data[`REORDER_BUFFER_SIZE-1];
assign data_to_speculative_instr_shift[`REORDER_BUFFER_SIZE-2] = reorder_buffer_shift_2 ? 32'b0 : 
speculative_instr_data[`REORDER_BUFFER_SIZE-1];
endgenerate
assign data_to_rd_mux_shift[`REORDER_BUFFER_SIZE-1] = 32'b0;
assign data_to_instr_complete_mux_shift[`REORDER_BUFFER_SIZE-1] = 1'b0;
assign data_to_rn_mux_shift[`REORDER_BUFFER_SIZE-1] = 32'b0;
assign data_to_cpsr_mux_shift[`REORDER_BUFFER_SIZE-1] = 32'b0;
assign data_to_speculative_instr_shift[`REORDER_BUFFER_SIZE-1] = 1'b0;
/*************************************RD_RN_CPSR_DATA_INSTR_COMPLETE_DATA_ENDS****************************************/

/***********************************DATA_ISSUE_TO_PIPES_STARTS****************************************/
/***********************************************/
/***********************************************/
assign rd_data_frm_ldm_buffer = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rd_addr_match_with_ldm_buffer[15]}}));
/***********************************************/
/***********************************************/
assign rn_data_frm_ldm_buffer[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] =  
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe1[15]}}));
/***********************************************/
/***********************************************/
assign rn_data_frm_ldm_buffer[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_alu_pipe2[15]}}));
/***********************************************/
/***********************************************/
assign rn_data_frm_ldm_buffer[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rn_addr_match_with_ldm_buffer_load_store_pipe3[15]}}));
/***********************************************/
/***********************************************/
assign rm_data_frm_ldm_buffer[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] =   
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe1[15]}}));
/***********************************************/
/***********************************************/
assign rm_data_frm_ldm_buffer[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_alu_pipe2[15]}}));
/***********************************************/
/***********************************************/
assign rm_data_frm_ldm_buffer[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_load_store_pipe3[15]}}));
/***********************************************/
/***********************************************/
assign rm_data_frm_ldm_buffer[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rm_addr_match_with_ldm_buffer_branch_pipe4[15]}}));
/***********************************************/
/***********************************************/
assign rs_data_frm_ldm_buffer[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe1[15]}}));
/***********************************************/
/***********************************************/
assign rs_data_frm_ldm_buffer[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_alu_pipe2[15]}}));
/***********************************************/
/***********************************************/
assign rs_data_frm_ldm_buffer[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] = 
((ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[0]}}) | 
(ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[1]}}) | 
(ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[2]}}) |
(ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[3]}}) |
(ldm_stm_data[4][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[4]}}) |
(ldm_stm_data[5][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[5]}}) |
(ldm_stm_data[6][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[6]}}) |
(ldm_stm_data[7][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[7]}}) |
(ldm_stm_data[8][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[8]}}) |
(ldm_stm_data[9][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[9]}}) |
(ldm_stm_data[10][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[10]}}) |
(ldm_stm_data[11][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[11]}}) |
(ldm_stm_data[12][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[12]}}) |
(ldm_stm_data[13][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[13]}}) |
(ldm_stm_data[14][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[14]}}) |
(ldm_stm_data[15][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] & 
{32{rs_addr_match_with_ldm_buffer_load_store_pipe3[15]}}));
/***********************************************/
/***********************************************/
genvar p;
generate
for(p=0;p<=`REORDER_BUFFER_SIZE-1;p=p+1)
begin : grp_data_to_issue_tag_match
	/***********************************************/
	/***********************************************/
	assign tag_issue_rd_match_load_store_pipe3[p] = 
	~(|(tag_bits_for_rd_to_issue_in ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
	
	assign rd_addr_issue_match_load_store_pipe3[p] = ~(|(rd_addr_to_issue_in ^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rd_addr_match_with_ldm_buffer[p] = ~(|(rd_addr_to_issue_in ^ 
	ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rd_data_issue_frm_reorder_buffer[p] = rd_addr_issue_match_load_store_pipe3[p] ? rn_data[p] : 
	rd_data[p];
	
	assign rd_data_issue_pipes[p] = reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rd_data_frm_ldm_buffer : rd_data_issue_frm_reorder_buffer[p];
	/***********************************************/
	/***********************************************/	
	assign tag_issue_rn_match_alu_pipe1[p] =  
	~(|(tag_bits_for_rn_to_issue_in[`TAG_RN_ISSUE_ALU_PIPE1_STARTS:`TAG_RN_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rn_addr_issue_match_alu_pipe1[p] =  
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_ALU_PIPE1_STARTS:`RN_ADDR_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rn_addr_match_with_ldm_buffer_alu_pipe1[p] = 
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_ALU_PIPE1_STARTS:`RN_ADDR_ISSUE_ALU_PIPE1_ENDS] ^ 
	ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rn_data_issue_frm_reorder_buffer[p][`RN_DATA_ALU_PIPE1_STARTS:
	`RN_DATA_ALU_PIPE1_ENDS] = rn_addr_issue_match_alu_pipe1[p] ? rn_data[p] : rd_data[p];
	
	assign rn_data_issue_pipes[p][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rn_data_frm_ldm_buffer[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] : 
	rn_data_issue_frm_reorder_buffer[p][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS];
	/***********************************************/
	/***********************************************/	
	assign tag_issue_rn_match_alu_pipe2[p] = 
	~(|(tag_bits_for_rn_to_issue_in[`TAG_RN_ISSUE_ALU_PIPE2_STARTS:`TAG_RN_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rn_addr_issue_match_alu_pipe2[p] =  
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_ALU_PIPE2_STARTS:`RN_ADDR_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rn_addr_match_with_ldm_buffer_alu_pipe2[p] = 
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_ALU_PIPE2_STARTS:`RN_ADDR_ISSUE_ALU_PIPE2_ENDS] ^ 
	ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rn_data_issue_frm_reorder_buffer[p][`RN_DATA_ALU_PIPE2_STARTS:
	`RN_DATA_ALU_PIPE2_ENDS] = rn_addr_issue_match_alu_pipe2[p] ? rn_data[p] : rd_data[p];
	
	assign rn_data_issue_pipes[p][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rn_data_frm_ldm_buffer[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] : 
	rn_data_issue_frm_reorder_buffer[p][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS];
	/***********************************************/
	/***********************************************/	
	assign tag_issue_rn_match_load_store_pipe3[p] = 
	~(|(tag_bits_for_rn_to_issue_in[`TAG_RN_ISSUE_LOAD_STORE_PIPE3_STARTS:
	`TAG_RN_ISSUE_LOAD_STORE_PIPE3_ENDS] ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
	
	assign rn_addr_issue_match_load_store_pipe3[p] =  
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RN_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rn_addr_match_with_ldm_buffer_load_store_pipe3[p] = 
	~(|(rn_addr_to_issue_in[`RN_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RN_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE]; 
	
	assign rn_data_issue_frm_reorder_buffer[p][`RN_DATA_LOAD_STORE_PIPE3_STARTS:
	`RN_DATA_LOAD_STORE_PIPE3_ENDS] = rn_addr_issue_match_load_store_pipe3[p] ? rn_data[p] : rd_data[p];
	
	assign rn_data_issue_pipes[p][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rn_data_frm_ldm_buffer[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] : 
	rn_data_issue_frm_reorder_buffer[p][`RN_DATA_LOAD_STORE_PIPE3_STARTS:
	`RN_DATA_LOAD_STORE_PIPE3_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rm_match_alu_pipe1[p] =  
	~(|(tag_bits_for_rm_to_issue_in[`TAG_RM_ISSUE_ALU_PIPE1_STARTS:`TAG_RM_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rm_addr_issue_match_alu_pipe1[p] =  
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_ALU_PIPE1_STARTS:`RM_ADDR_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rm_addr_match_with_ldm_buffer_alu_pipe1[p] = 
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_ALU_PIPE1_STARTS:`RM_ADDR_ISSUE_ALU_PIPE1_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rm_data_issue_frm_reorder_buffer[p][`RM_DATA_ALU_PIPE1_STARTS:
	`RM_DATA_ALU_PIPE1_ENDS] = rm_addr_issue_match_alu_pipe1[p] ? rn_data[p] : rd_data[p];
	
	assign rm_data_issue_pipes[p][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rm_data_frm_ldm_buffer[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] : 
	rm_data_issue_frm_reorder_buffer[p][`RM_DATA_ALU_PIPE1_STARTS:
	`RM_DATA_ALU_PIPE1_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rm_match_alu_pipe2[p] = 
	~(|(tag_bits_for_rm_to_issue_in[`TAG_RM_ISSUE_ALU_PIPE2_STARTS:`TAG_RM_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rm_addr_issue_match_alu_pipe2[p] =  
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_ALU_PIPE2_STARTS:`RM_ADDR_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rm_addr_match_with_ldm_buffer_alu_pipe2[p] = 
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_ALU_PIPE2_STARTS:`RM_ADDR_ISSUE_ALU_PIPE2_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rm_data_issue_frm_reorder_buffer[p][`RM_DATA_ALU_PIPE2_STARTS:
	`RM_DATA_ALU_PIPE2_ENDS] = rm_addr_issue_match_alu_pipe2[p] ? rn_data[p] : rd_data[p];
	
	assign rm_data_issue_pipes[p][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rm_data_frm_ldm_buffer[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] : 
	rm_data_issue_frm_reorder_buffer[p][`RM_DATA_ALU_PIPE2_STARTS:
	`RM_DATA_ALU_PIPE2_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rm_match_load_store_pipe3[p] = 
	~(|(tag_bits_for_rm_to_issue_in[`TAG_RM_ISSUE_LOAD_STORE_PIPE3_STARTS:
	`TAG_RM_ISSUE_LOAD_STORE_PIPE3_ENDS] ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
	
	assign rm_addr_issue_match_load_store_pipe3[p] =  
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RM_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rm_addr_match_with_ldm_buffer_load_store_pipe3[p] = 
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RM_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rm_data_issue_frm_reorder_buffer[p][`RM_DATA_LOAD_STORE_PIPE3_STARTS:
	`RM_DATA_LOAD_STORE_PIPE3_ENDS] = rm_addr_issue_match_load_store_pipe3[p] ? rn_data[p] : rd_data[p];
	
	assign rm_data_issue_pipes[p][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rm_data_frm_ldm_buffer[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] : 
	rm_data_issue_frm_reorder_buffer[p][`RM_DATA_LOAD_STORE_PIPE3_STARTS:
	`RM_DATA_LOAD_STORE_PIPE3_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rm_match_branch_pipe4[p] = 
	~(|(tag_bits_for_rm_to_issue_in[`TAG_RM_ISSUE_BRANCH_PIPE4_STARTS:`TAG_RM_ISSUE_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rm_addr_issue_match_branch_pipe4[p] =  
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_BRANCH_PIPE4_STARTS:`RM_ADDR_ISSUE_BRANCH_PIPE4_ENDS]	^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rm_addr_match_with_ldm_buffer_branch_pipe4[p] = 
	~(|(rm_addr_to_issue_in[`RM_ADDR_ISSUE_BRANCH_PIPE4_STARTS:`RM_ADDR_ISSUE_BRANCH_PIPE4_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rm_data_issue_frm_reorder_buffer[p][`RM_DATA_BRANCH_PIPE4_STARTS:
	`RM_DATA_BRANCH_PIPE4_ENDS] = rm_addr_issue_match_branch_pipe4[p] ? rn_data[p] : rd_data[p];
	
	assign rm_data_issue_pipes[p][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rm_data_frm_ldm_buffer[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] : 
	rm_data_issue_frm_reorder_buffer[p][`RM_DATA_BRANCH_PIPE4_STARTS:
	`RM_DATA_BRANCH_PIPE4_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rs_match_alu_pipe1[p] = 
	~(|(tag_bits_for_rs_to_issue_in[`TAG_RS_ISSUE_ALU_PIPE1_STARTS:`TAG_RS_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rs_addr_issue_match_alu_pipe1[p] =  
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_ALU_PIPE1_STARTS:`RS_ADDR_ISSUE_ALU_PIPE1_ENDS]	^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rs_addr_match_with_ldm_buffer_alu_pipe1[p] = 
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_ALU_PIPE1_STARTS:`RS_ADDR_ISSUE_ALU_PIPE1_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rs_data_issue_frm_reorder_buffer[p][`RS_DATA_ALU_PIPE1_STARTS:
	`RS_DATA_ALU_PIPE1_ENDS] = rs_addr_issue_match_alu_pipe1[p] ? rn_data[p] : rd_data[p];
	
	assign rs_data_issue_pipes[p][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rs_data_frm_ldm_buffer[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] : 
	rs_data_issue_frm_reorder_buffer[p][`RS_DATA_ALU_PIPE1_STARTS:
	`RS_DATA_ALU_PIPE1_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rs_match_alu_pipe2[p] = 
	~(|(tag_bits_for_rs_to_issue_in[`TAG_RS_ISSUE_ALU_PIPE2_STARTS:`TAG_RS_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	
	assign rs_addr_issue_match_alu_pipe2[p] =  
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_ALU_PIPE2_STARTS:`RS_ADDR_ISSUE_ALU_PIPE2_ENDS]	^ 
	reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rs_addr_match_with_ldm_buffer_alu_pipe2[p] = 
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_ALU_PIPE2_STARTS:`RS_ADDR_ISSUE_ALU_PIPE2_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rs_data_issue_frm_reorder_buffer[p][`RS_DATA_ALU_PIPE2_STARTS:
	`RS_DATA_ALU_PIPE2_ENDS] = rs_addr_issue_match_alu_pipe2[p] ? rn_data[p] : rd_data[p];
	
	assign rs_data_issue_pipes[p][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rs_data_frm_ldm_buffer[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] : 
	rs_data_issue_frm_reorder_buffer[p][`RS_DATA_ALU_PIPE2_STARTS:
	`RS_DATA_ALU_PIPE2_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_rs_match_load_store_pipe3[p] = 
	~(|(tag_bits_for_rs_to_issue_in[`TAG_RS_ISSUE_LOAD_STORE_PIPE3_STARTS:
	`TAG_RS_ISSUE_LOAD_STORE_PIPE3_ENDS] ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
	
	assign rs_addr_issue_match_load_store_pipe3[p] =  
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RS_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ reorder_buffer[p][`RB_RN_ADDR_START:`RB_RN_ADDR_END]));
	
	assign rs_addr_match_with_ldm_buffer_load_store_pipe3[p] = 
	~(|(rs_addr_to_issue_in[`RS_ADDR_ISSUE_LOAD_STORE_PIPE3_STARTS:`RS_ADDR_ISSUE_LOAD_STORE_PIPE3_ENDS]
	^ ldm_stm_data[p][`LDM_STM_DATA_RD_ADDR_STARTS:`LDM_STM_DATA_RD_ADDR_ENDS])) & 
	ldm_stm_data[p][`LDM_STM_DATA_ENABLE];
	
	assign rs_data_issue_frm_reorder_buffer[p][`RS_DATA_LOAD_STORE_PIPE3_STARTS:
	`RS_DATA_LOAD_STORE_PIPE3_ENDS] = rs_addr_issue_match_load_store_pipe3[p] ? rn_data[p] : rd_data[p];
	
	assign rs_data_issue_pipes[p][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] = 
	reorder_buffer[p][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] ? 
	rs_data_frm_ldm_buffer[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] : 
	rs_data_issue_frm_reorder_buffer[p][`RS_DATA_LOAD_STORE_PIPE3_STARTS:
	`RS_DATA_LOAD_STORE_PIPE3_ENDS];
	/***********************************************/
	/***********************************************/
	assign tag_issue_cpsr_match_alu_pipe1[p] = 
	~(|(tag_bits_for_cpsr_to_issue_in[`TAG_CPSR_ISSUE_ALU_PIPE1_STARTS:`TAG_CPSR_ISSUE_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	assign tag_issue_cpsr_match_alu_pipe2[p] = 
	~(|(tag_bits_for_cpsr_to_issue_in[`TAG_CPSR_ISSUE_ALU_PIPE2_STARTS:`TAG_CPSR_ISSUE_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & reorder_buffer_position_occupied[p];
	assign tag_issue_cpsr_match_load_store_pipe3[p] = 
	~(|(tag_bits_for_cpsr_to_issue_in[`TAG_CPSR_ISSUE_LOAD_STORE_PIPE3_STARTS:
	`TAG_CPSR_ISSUE_LOAD_STORE_PIPE3_ENDS] ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
	assign tag_issue_cpsr_match_branch_pipe4[p] = 
	~(|(tag_bits_for_cpsr_to_issue_in[`TAG_CPSR_ISSUE_BRANCH_PIPE4_STARTS:
	`TAG_CPSR_ISSUE_BRANCH_PIPE4_ENDS] ^ reorder_buffer[p][`RB_TAG_START:`RB_TAG_END])) & 
	reorder_buffer_position_occupied[p];
end
endgenerate

/***********************************RD_ISSUE_TO_PIPES_STARTS****************************************/
assign rd_data_to_pipes = ({32{tag_issue_rd_match_load_store_pipe3[0]}} & rd_data_issue_pipes[0]) | 
({32{tag_issue_rd_match_load_store_pipe3[1]}} & rd_data_issue_pipes[1]) | 
({32{tag_issue_rd_match_load_store_pipe3[2]}} & rd_data_issue_pipes[2]) | 
({32{tag_issue_rd_match_load_store_pipe3[3]}} & rd_data_issue_pipes[3]) | 
({32{tag_issue_rd_match_load_store_pipe3[4]}} & rd_data_issue_pipes[4]) | 
({32{tag_issue_rd_match_load_store_pipe3[5]}} & rd_data_issue_pipes[5]) | 
({32{tag_issue_rd_match_load_store_pipe3[6]}} & rd_data_issue_pipes[6]) | 
({32{tag_issue_rd_match_load_store_pipe3[7]}} & rd_data_issue_pipes[7]) | 
({32{tag_issue_rd_match_load_store_pipe3[8]}} & rd_data_issue_pipes[8]) | 
({32{tag_issue_rd_match_load_store_pipe3[9]}} & rd_data_issue_pipes[9]) | 
({32{tag_issue_rd_match_load_store_pipe3[10]}} & rd_data_issue_pipes[10]) | 
({32{tag_issue_rd_match_load_store_pipe3[11]}} & rd_data_issue_pipes[11]) | 
({32{tag_issue_rd_match_load_store_pipe3[12]}} & rd_data_issue_pipes[12]) | 
({32{tag_issue_rd_match_load_store_pipe3[13]}} & rd_data_issue_pipes[13]) | 
({32{tag_issue_rd_match_load_store_pipe3[14]}} & rd_data_issue_pipes[14]) | 
({32{tag_issue_rd_match_load_store_pipe3[15]}} & rd_data_issue_pipes[15]); 

assign rd_data_to_pipes_out = (|(tag_issue_rd_match_load_store_pipe3)) ? rd_data_to_pipes : 
rd_data_issue_pipes_frm_reg_file_in;
/***********************************RD_ISSUE_TO_PIPES_ENDS****************************************/

/***********************************RN_ISSUE_TO_PIPES_STARTS****************************************/
assign rn_data_to_issue_pipes[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] = 
({32{tag_issue_rn_match_alu_pipe1[0]}} & 
rn_data_issue_pipes[0][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[1]}} & 
rn_data_issue_pipes[1][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[2]}} & 
rn_data_issue_pipes[2][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[3]}} & 
rn_data_issue_pipes[3][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[4]}} & 
rn_data_issue_pipes[4][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[5]}} & 
rn_data_issue_pipes[5][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[6]}} & 
rn_data_issue_pipes[6][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[7]}} & 
rn_data_issue_pipes[7][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[8]}} & 
rn_data_issue_pipes[8][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[9]}} & 
rn_data_issue_pipes[9][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[10]}} & 
rn_data_issue_pipes[10][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[11]}} & 
rn_data_issue_pipes[11][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[12]}} & 
rn_data_issue_pipes[12][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[13]}} & 
rn_data_issue_pipes[13][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[14]}} & 
rn_data_issue_pipes[14][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe1[15]}} & 
rn_data_issue_pipes[15][`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS]);


assign rn_data_to_issue_pipes[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] = 
({32{tag_issue_rn_match_alu_pipe2[0]}} & 
rn_data_issue_pipes[0][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[1]}} & 
rn_data_issue_pipes[1][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[2]}} & 
rn_data_issue_pipes[2][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[3]}} & 
rn_data_issue_pipes[3][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[4]}} & 
rn_data_issue_pipes[4][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[5]}} & 
rn_data_issue_pipes[5][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[6]}} & 
rn_data_issue_pipes[6][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[7]}} & 
rn_data_issue_pipes[7][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[8]}} & 
rn_data_issue_pipes[8][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[9]}} & 
rn_data_issue_pipes[9][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[10]}} & 
rn_data_issue_pipes[10][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[11]}} & 
rn_data_issue_pipes[11][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[12]}} & 
rn_data_issue_pipes[12][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[13]}} & 
rn_data_issue_pipes[13][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[14]}} & 
rn_data_issue_pipes[14][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rn_match_alu_pipe2[15]}} & 
rn_data_issue_pipes[15][`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS]);

assign rn_data_to_issue_pipes[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] = 
({32{tag_issue_rn_match_load_store_pipe3[0]}} & 
rn_data_issue_pipes[0][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[1]}} & 
rn_data_issue_pipes[1][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[2]}} & 
rn_data_issue_pipes[2][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[3]}} & 
rn_data_issue_pipes[3][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[4]}} & 
rn_data_issue_pipes[4][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[5]}} & 
rn_data_issue_pipes[5][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[6]}} & 
rn_data_issue_pipes[6][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[7]}} & 
rn_data_issue_pipes[7][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[8]}} & 
rn_data_issue_pipes[8][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[9]}} & 
rn_data_issue_pipes[9][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[10]}} & 
rn_data_issue_pipes[10][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[11]}} & 
rn_data_issue_pipes[11][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[12]}} & 
rn_data_issue_pipes[12][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[13]}} & 
rn_data_issue_pipes[13][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[14]}} & 
rn_data_issue_pipes[14][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rn_match_load_store_pipe3[15]}} & 
rn_data_issue_pipes[15][`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS]);

assign rn_data_to_issue_pipes_out[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] = 
(|(tag_issue_rn_match_alu_pipe1)) ? 
rn_data_to_issue_pipes[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS] : 
rn_data_issue_pipes_frm_reg_file_in[`RN_DATA_ALU_PIPE1_STARTS:`RN_DATA_ALU_PIPE1_ENDS];

assign rn_data_to_issue_pipes_out[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] = 
(|(tag_issue_rn_match_alu_pipe2)) ? 
rn_data_to_issue_pipes[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS] : 
rn_data_issue_pipes_frm_reg_file_in[`RN_DATA_ALU_PIPE2_STARTS:`RN_DATA_ALU_PIPE2_ENDS];

assign rn_data_to_issue_pipes_out[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] = 
(|(tag_issue_rn_match_load_store_pipe3)) ? 
rn_data_to_issue_pipes[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS] : 
rn_data_issue_pipes_frm_reg_file_in[`RN_DATA_LOAD_STORE_PIPE3_STARTS:`RN_DATA_LOAD_STORE_PIPE3_ENDS];
/***********************************RN_ISSUE_TO_PIPES_ENDS****************************************/

/***********************************RM_ISSUE_TO_PIPES_STARTS****************************************/
assign rm_data_to_issue_pipes[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] = 
({32{tag_issue_rm_match_alu_pipe1[0]}} & 
rm_data_issue_pipes[0][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[1]}} & 
rm_data_issue_pipes[1][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[2]}} & 
rm_data_issue_pipes[2][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[3]}} & 
rm_data_issue_pipes[3][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[4]}} & 
rm_data_issue_pipes[4][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[5]}} & 
rm_data_issue_pipes[5][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[6]}} & 
rm_data_issue_pipes[6][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[7]}} & 
rm_data_issue_pipes[7][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[8]}} & 
rm_data_issue_pipes[8][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[9]}} & 
rm_data_issue_pipes[9][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[10]}} & 
rm_data_issue_pipes[10][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[11]}} & 
rm_data_issue_pipes[11][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[12]}} & 
rm_data_issue_pipes[12][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[13]}} & 
rm_data_issue_pipes[13][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[14]}} & 
rm_data_issue_pipes[14][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe1[15]}} & 
rm_data_issue_pipes[15][`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS]);

assign rm_data_to_issue_pipes[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] = 
({32{tag_issue_rm_match_alu_pipe2[0]}} & 
rm_data_issue_pipes[0][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[1]}} & 
rm_data_issue_pipes[1][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[2]}} & 
rm_data_issue_pipes[2][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[3]}} & 
rm_data_issue_pipes[3][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[4]}} & 
rm_data_issue_pipes[4][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[5]}} & 
rm_data_issue_pipes[5][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[6]}} & 
rm_data_issue_pipes[6][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[7]}} & 
rm_data_issue_pipes[7][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[8]}} & 
rm_data_issue_pipes[8][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[9]}} & 
rm_data_issue_pipes[9][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[10]}} & 
rm_data_issue_pipes[10][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[11]}} & 
rm_data_issue_pipes[11][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[12]}} & 
rm_data_issue_pipes[12][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[13]}} & 
rm_data_issue_pipes[13][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[14]}} & 
rm_data_issue_pipes[14][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rm_match_alu_pipe2[15]}} & 
rm_data_issue_pipes[15][`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS]);

assign rm_data_to_issue_pipes[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] = 
({32{tag_issue_rm_match_load_store_pipe3[0]}} & 
rm_data_issue_pipes[0][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[1]}} & 
rm_data_issue_pipes[1][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[2]}} & 
rm_data_issue_pipes[2][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[3]}} & 
rm_data_issue_pipes[3][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[4]}} & 
rm_data_issue_pipes[4][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[5]}} & 
rm_data_issue_pipes[5][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[6]}} & 
rm_data_issue_pipes[6][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[7]}} & 
rm_data_issue_pipes[7][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[8]}} & 
rm_data_issue_pipes[8][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[9]}} & 
rm_data_issue_pipes[9][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[10]}} & 
rm_data_issue_pipes[10][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[11]}} & 
rm_data_issue_pipes[11][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[12]}} & 
rm_data_issue_pipes[12][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[13]}} & 
rm_data_issue_pipes[13][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[14]}} & 
rm_data_issue_pipes[14][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rm_match_load_store_pipe3[15]}} & 
rm_data_issue_pipes[15][`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS]);

assign rm_data_to_issue_pipes[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] = 
({32{tag_issue_rm_match_branch_pipe4[0]}} & 
rm_data_issue_pipes[0][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[1]}} & 
rm_data_issue_pipes[1][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[2]}} & 
rm_data_issue_pipes[2][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[3]}} & 
rm_data_issue_pipes[3][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[4]}} & 
rm_data_issue_pipes[4][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[5]}} & 
rm_data_issue_pipes[5][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[6]}} & 
rm_data_issue_pipes[6][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[7]}} & 
rm_data_issue_pipes[7][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[8]}} & 
rm_data_issue_pipes[8][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[9]}} & 
rm_data_issue_pipes[9][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[10]}} & 
rm_data_issue_pipes[10][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[11]}} & 
rm_data_issue_pipes[11][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[12]}} & 
rm_data_issue_pipes[12][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[13]}} & 
rm_data_issue_pipes[13][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[14]}} & 
rm_data_issue_pipes[14][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]) | 
({32{tag_issue_rm_match_branch_pipe4[15]}} & 
rm_data_issue_pipes[15][`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS]);

assign rm_data_to_issue_pipes_out[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] = 
(|(tag_issue_rm_match_alu_pipe1)) ? 
rm_data_to_issue_pipes[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS] : 
rm_data_issue_pipes_frm_reg_file_in[`RM_DATA_ALU_PIPE1_STARTS:`RM_DATA_ALU_PIPE1_ENDS];

assign rm_data_to_issue_pipes_out[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] = 
(|(tag_issue_rm_match_alu_pipe2)) ? 
rm_data_to_issue_pipes[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS] : 
rm_data_issue_pipes_frm_reg_file_in[`RM_DATA_ALU_PIPE2_STARTS:`RM_DATA_ALU_PIPE2_ENDS];

assign rm_data_to_issue_pipes_out[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] = 
(|(tag_issue_rm_match_load_store_pipe3)) ? 
rm_data_to_issue_pipes[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS] : 
rm_data_issue_pipes_frm_reg_file_in[`RM_DATA_LOAD_STORE_PIPE3_STARTS:`RM_DATA_LOAD_STORE_PIPE3_ENDS];

assign rm_data_to_issue_pipes_out[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] = 
(|(tag_issue_rm_match_branch_pipe4)) ? 
rm_data_to_issue_pipes[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS] : 
rm_data_issue_pipes_frm_reg_file_in[`RM_DATA_BRANCH_PIPE4_STARTS:`RM_DATA_BRANCH_PIPE4_ENDS];
/***********************************RM_ISSUE_TO_PIPES_ENDS****************************************/

/***********************************RS_ISSUE_TO_PIPES_STARTS****************************************/
assign rs_data_to_issue_pipes[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] = 
({32{tag_issue_rs_match_alu_pipe1[0]}} & 
rs_data_issue_pipes[0][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[1]}} & 
rs_data_issue_pipes[1][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[2]}} & 
rs_data_issue_pipes[2][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[3]}} & 
rs_data_issue_pipes[3][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[4]}} & 
rs_data_issue_pipes[4][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[5]}} & 
rs_data_issue_pipes[5][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[6]}} & 
rs_data_issue_pipes[6][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[7]}} & 
rs_data_issue_pipes[7][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[8]}} & 
rs_data_issue_pipes[8][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[9]}} & 
rs_data_issue_pipes[9][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[10]}} & 
rs_data_issue_pipes[10][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[11]}} & 
rs_data_issue_pipes[11][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[12]}} & 
rs_data_issue_pipes[12][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[13]}} & 
rs_data_issue_pipes[13][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[14]}} & 
rs_data_issue_pipes[14][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe1[15]}} & 
rs_data_issue_pipes[15][`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS]);

assign rs_data_to_issue_pipes[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] = 
({32{tag_issue_rs_match_alu_pipe2[0]}} & 
rs_data_issue_pipes[0][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[1]}} & 
rs_data_issue_pipes[1][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[2]}} & 
rs_data_issue_pipes[2][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[3]}} & 
rs_data_issue_pipes[3][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[4]}} & 
rs_data_issue_pipes[4][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[5]}} & 
rs_data_issue_pipes[5][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[6]}} & 
rs_data_issue_pipes[6][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[7]}} & 
rs_data_issue_pipes[7][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[8]}} & 
rs_data_issue_pipes[8][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[9]}} & 
rs_data_issue_pipes[9][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[10]}} & 
rs_data_issue_pipes[10][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[11]}} & 
rs_data_issue_pipes[11][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[12]}} & 
rs_data_issue_pipes[12][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[13]}} & 
rs_data_issue_pipes[13][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[14]}} & 
rs_data_issue_pipes[14][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]) | 
({32{tag_issue_rs_match_alu_pipe2[15]}} & 
rs_data_issue_pipes[15][`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS]);

assign rs_data_to_issue_pipes[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] = 
({32{tag_issue_rs_match_load_store_pipe3[0]}} & 
rs_data_issue_pipes[0][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[1]}} & 
rs_data_issue_pipes[1][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[2]}} & 
rs_data_issue_pipes[2][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[3]}} & 
rs_data_issue_pipes[3][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[4]}} & 
rs_data_issue_pipes[4][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[5]}} & 
rs_data_issue_pipes[5][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[6]}} & 
rs_data_issue_pipes[6][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[7]}} & 
rs_data_issue_pipes[7][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[8]}} & 
rs_data_issue_pipes[8][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[9]}} & 
rs_data_issue_pipes[9][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[10]}} & 
rs_data_issue_pipes[10][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[11]}} & 
rs_data_issue_pipes[11][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[12]}} & 
rs_data_issue_pipes[12][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[13]}} & 
rs_data_issue_pipes[13][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[14]}} & 
rs_data_issue_pipes[14][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]) | 
({32{tag_issue_rs_match_load_store_pipe3[15]}} & 
rs_data_issue_pipes[15][`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS]);

assign rs_data_to_issue_pipes_out[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] = 
(|(tag_issue_rs_match_alu_pipe1)) ? 
rs_data_to_issue_pipes[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS] : 
rs_data_issue_pipes_frm_reg_file_in[`RS_DATA_ALU_PIPE1_STARTS:`RS_DATA_ALU_PIPE1_ENDS];

assign rs_data_to_issue_pipes_out[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] = 
(|(tag_issue_rs_match_alu_pipe2)) ? 
rs_data_to_issue_pipes[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS] : 
rs_data_issue_pipes_frm_reg_file_in[`RS_DATA_ALU_PIPE2_STARTS:`RS_DATA_ALU_PIPE2_ENDS];

assign rs_data_to_issue_pipes_out[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] = 
(|(tag_issue_rs_match_load_store_pipe3)) ? 
rs_data_to_issue_pipes[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS] : 
rs_data_issue_pipes_frm_reg_file_in[`RS_DATA_LOAD_STORE_PIPE3_STARTS:`RS_DATA_LOAD_STORE_PIPE3_ENDS];
/***********************************RS_ISSUE_TO_PIPES_ENDS****************************************/

/***********************************CPSR_ISSUE_TO_PIPES_STARTS****************************************/
assign cpsr_data_to_issue_pipes[`CPSR_DATA_ALU_PIPE1_STARTS:`CPSR_DATA_ALU_PIPE1_ENDS] = 
({32{tag_issue_cpsr_match_alu_pipe1[0]}} & cpsr_data[0]) | 
({32{tag_issue_cpsr_match_alu_pipe1[1]}} & cpsr_data[1]) | 
({32{tag_issue_cpsr_match_alu_pipe1[2]}} & cpsr_data[2]) | 
({32{tag_issue_cpsr_match_alu_pipe1[3]}} & cpsr_data[3]) | 
({32{tag_issue_cpsr_match_alu_pipe1[4]}} & cpsr_data[4]) | 
({32{tag_issue_cpsr_match_alu_pipe1[5]}} & cpsr_data[5]) | 
({32{tag_issue_cpsr_match_alu_pipe1[6]}} & cpsr_data[6]) | 
({32{tag_issue_cpsr_match_alu_pipe1[7]}} & cpsr_data[7]) | 
({32{tag_issue_cpsr_match_alu_pipe1[8]}} & cpsr_data[8]) |
({32{tag_issue_cpsr_match_alu_pipe1[9]}} & cpsr_data[9]) | 
({32{tag_issue_cpsr_match_alu_pipe1[10]}} & cpsr_data[10]) | 
({32{tag_issue_cpsr_match_alu_pipe1[11]}} & cpsr_data[11]) | 
({32{tag_issue_cpsr_match_alu_pipe1[12]}} & cpsr_data[12]) | 
({32{tag_issue_cpsr_match_alu_pipe1[13]}} & cpsr_data[13]) | 
({32{tag_issue_cpsr_match_alu_pipe1[14]}} & cpsr_data[14]) | 
({32{tag_issue_cpsr_match_alu_pipe1[15]}} & cpsr_data[15]);

assign cpsr_data_to_issue_pipes[`CPSR_DATA_ALU_PIPE2_STARTS:`CPSR_DATA_ALU_PIPE2_ENDS] = 
({32{tag_issue_cpsr_match_alu_pipe2[0]}} & cpsr_data[0]) |
({32{tag_issue_cpsr_match_alu_pipe2[1]}} & cpsr_data[1]) | 
({32{tag_issue_cpsr_match_alu_pipe2[2]}} & cpsr_data[2]) | 
({32{tag_issue_cpsr_match_alu_pipe2[3]}} & cpsr_data[3]) | 
({32{tag_issue_cpsr_match_alu_pipe2[4]}} & cpsr_data[4]) | 
({32{tag_issue_cpsr_match_alu_pipe2[5]}} & cpsr_data[5]) | 
({32{tag_issue_cpsr_match_alu_pipe2[6]}} & cpsr_data[6]) | 
({32{tag_issue_cpsr_match_alu_pipe2[7]}} & cpsr_data[7]) | 
({32{tag_issue_cpsr_match_alu_pipe2[8]}} & cpsr_data[8]) | 
({32{tag_issue_cpsr_match_alu_pipe2[9]}} & cpsr_data[9]) | 
({32{tag_issue_cpsr_match_alu_pipe2[10]}} & cpsr_data[10]) | 
({32{tag_issue_cpsr_match_alu_pipe2[11]}} & cpsr_data[11]) | 
({32{tag_issue_cpsr_match_alu_pipe2[12]}} & cpsr_data[12]) | 
({32{tag_issue_cpsr_match_alu_pipe2[13]}} & cpsr_data[13]) | 
({32{tag_issue_cpsr_match_alu_pipe2[14]}} & cpsr_data[14]) | 
({32{tag_issue_cpsr_match_alu_pipe2[15]}} & cpsr_data[15]);

assign cpsr_data_to_issue_pipes[`CPSR_DATA_LOAD_STORE_PIPE3_STARTS:
`CPSR_DATA_LOAD_STORE_PIPE3_ENDS] = ({32{tag_issue_cpsr_match_load_store_pipe3[0]}} & cpsr_data[0]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[1]}} & cpsr_data[1]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[2]}} & cpsr_data[2]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[3]}} & cpsr_data[3]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[4]}} & cpsr_data[4]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[5]}} & cpsr_data[5]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[6]}} & cpsr_data[6]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[7]}} & cpsr_data[7]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[8]}} & cpsr_data[8]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[9]}} & cpsr_data[9]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[10]}} & cpsr_data[10]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[11]}} & cpsr_data[11]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[12]}} & cpsr_data[12]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[13]}} & cpsr_data[13]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[14]}} & cpsr_data[14]) | 
({32{tag_issue_cpsr_match_load_store_pipe3[15]}} & cpsr_data[15]);

assign cpsr_data_to_issue_pipes[`CPSR_DATA_BRANCH_PIPE4_STARTS:`CPSR_DATA_BRANCH_PIPE4_ENDS] = 
({32{tag_issue_cpsr_match_branch_pipe4[0]}} & cpsr_data[0]) | 
({32{tag_issue_cpsr_match_branch_pipe4[1]}} & cpsr_data[1]) | 
({32{tag_issue_cpsr_match_branch_pipe4[2]}} & cpsr_data[2]) | 
({32{tag_issue_cpsr_match_branch_pipe4[3]}} & cpsr_data[3]) | 
({32{tag_issue_cpsr_match_branch_pipe4[4]}} & cpsr_data[4]) | 
({32{tag_issue_cpsr_match_branch_pipe4[5]}} & cpsr_data[5]) | 
({32{tag_issue_cpsr_match_branch_pipe4[6]}} & cpsr_data[6]) | 
({32{tag_issue_cpsr_match_branch_pipe4[7]}} & cpsr_data[7]) | 
({32{tag_issue_cpsr_match_branch_pipe4[8]}} & cpsr_data[8]) | 
({32{tag_issue_cpsr_match_branch_pipe4[9]}} & cpsr_data[9]) | 
({32{tag_issue_cpsr_match_branch_pipe4[10]}} & cpsr_data[10]) | 
({32{tag_issue_cpsr_match_branch_pipe4[11]}} & cpsr_data[11]) | 
({32{tag_issue_cpsr_match_branch_pipe4[12]}} & cpsr_data[12]) | 
({32{tag_issue_cpsr_match_branch_pipe4[13]}} & cpsr_data[13]) | 
({32{tag_issue_cpsr_match_branch_pipe4[14]}} & cpsr_data[14]) | 
({32{tag_issue_cpsr_match_branch_pipe4[15]}} & cpsr_data[15]);

assign cpsr_data_to_issue_pipes_out[`CPSR_DATA_ALU_PIPE1_STARTS:`CPSR_DATA_ALU_PIPE1_ENDS] = 
(|(tag_issue_cpsr_match_alu_pipe1)) ? 
cpsr_data_to_issue_pipes[`CPSR_DATA_ALU_PIPE1_STARTS:`CPSR_DATA_ALU_PIPE1_ENDS] : 
cpsr_data_issue_pipes_frm_reg_file_in;

assign cpsr_data_to_issue_pipes_out[`CPSR_DATA_ALU_PIPE2_STARTS:`CPSR_DATA_ALU_PIPE2_ENDS] = 
(|(tag_issue_cpsr_match_alu_pipe2)) ? 
cpsr_data_to_issue_pipes[`CPSR_DATA_ALU_PIPE2_STARTS:`CPSR_DATA_ALU_PIPE2_ENDS] : 
cpsr_data_issue_pipes_frm_reg_file_in;

assign cpsr_data_to_issue_pipes_out[`CPSR_DATA_LOAD_STORE_PIPE3_STARTS:
`CPSR_DATA_LOAD_STORE_PIPE3_ENDS] = (|(tag_issue_cpsr_match_load_store_pipe3)) ? 
cpsr_data_to_issue_pipes[`CPSR_DATA_LOAD_STORE_PIPE3_STARTS:`CPSR_DATA_LOAD_STORE_PIPE3_ENDS] : 
cpsr_data_issue_pipes_frm_reg_file_in;

assign cpsr_data_to_issue_pipes_out[`CPSR_DATA_BRANCH_PIPE4_STARTS:`CPSR_DATA_BRANCH_PIPE4_ENDS] = 
(|(tag_issue_cpsr_match_branch_pipe4)) ? 
cpsr_data_to_issue_pipes[`CPSR_DATA_BRANCH_PIPE4_STARTS:`CPSR_DATA_BRANCH_PIPE4_ENDS] : 
cpsr_data_issue_pipes_frm_reg_file_in;
/***********************************CPSR_ISSUE_TO_PIPES_ENDS****************************************/

/***********************************DATA_ISSUE_TO_PIPES_ENDS****************************************/

/******TAG_RETIRE_STARTS******/
/******RD_STARTS******/
assign tag_retire_pipes_for_rd_out[3] = (|(tag_retire_pipes_rd[3]) | (tag_change_pipes_rd[3] & 
(~(|tag_change_selector_for_rd_final_specu_alu_pipe1) | (new_tag_instr_complete_for_rd_alu_pipe1 & 
(~new_tag_speculative_instr_for_rd_alu_pipe1 | new_tag_speculative_result_for_rd_alu_pipe1)))));
assign tag_retire_pipes_for_rd_out[2] = (|(tag_retire_pipes_rd[2]) | (tag_change_pipes_rd[2] & 
(~(|tag_change_selector_for_rd_final_specu_alu_pipe2) | (new_tag_instr_complete_for_rd_alu_pipe2 & 
(~new_tag_speculative_instr_for_rd_alu_pipe2 | new_tag_speculative_result_for_rd_alu_pipe2)))));
assign tag_retire_pipes_for_rd_out[1] = (|(tag_retire_pipes_rd[1]) | (tag_change_pipes_rd[1] & 
(~(|tag_change_selector_for_rd_final_specu_load_store_pipe3) | 
(new_tag_instr_complete_for_rd_load_store_pipe3 & (~new_tag_speculative_instr_for_rd_load_store_pipe3 | 
new_tag_speculative_result_for_rd_load_store_pipe3)))));
assign tag_retire_pipes_for_rd_out[0] = (|(tag_retire_pipes_rd[0]) | (tag_change_pipes_rd[0] & 
(~(|tag_change_selector_for_rd_final_specu_branch_pipe4) | (new_tag_instr_complete_for_rd_branch_pipe4
& (~new_tag_speculative_instr_for_rd_branch_pipe4 | 
new_tag_speculative_result_for_rd_branch_pipe4)))));
/******RD_ENDS******/
/******RN_STARTS******/
assign tag_retire_pipes_for_rn_out[3] = (|(tag_retire_pipes_rn[3]) | (tag_change_pipes_rn[3] & 
(~(|tag_change_selector_for_rn_final_specu_alu_pipe1) | (new_tag_instr_complete_for_rn_alu_pipe1 & 
(~new_tag_speculative_instr_for_rn_alu_pipe1 | new_tag_speculative_result_for_rn_alu_pipe1)))));
assign tag_retire_pipes_for_rn_out[2] = (|(tag_retire_pipes_rn[2]) | (tag_change_pipes_rn[2] & 
(~(|tag_change_selector_for_rn_final_specu_alu_pipe2) | (new_tag_instr_complete_for_rn_alu_pipe2 & 
(~new_tag_speculative_instr_for_rn_alu_pipe2 | new_tag_speculative_result_for_rn_alu_pipe2)))));
assign tag_retire_pipes_for_rn_out[1] = (|(tag_retire_pipes_rn[1]) | (tag_change_pipes_rn[1] & 
(~(|tag_change_selector_for_rn_final_specu_load_store_pipe3) | 
(new_tag_instr_complete_for_rn_load_store_pipe3 & (~new_tag_speculative_instr_for_rn_load_store_pipe3 | 
new_tag_speculative_result_for_rn_load_store_pipe3)))));
assign tag_retire_pipes_for_rn_out[0] = (|(tag_retire_pipes_rn[0]) | (tag_change_pipes_rn[0] & 
(~(|tag_change_selector_for_rn_final_specu_branch_pipe4) | (new_tag_instr_complete_for_rn_branch_pipe4
& (~new_tag_speculative_instr_for_rn_branch_pipe4 | 
new_tag_speculative_result_for_rn_branch_pipe4)))));
/******RN_ENDS******/
/******CPSR_STARTS******/
assign tag_retire_pipes_for_cpsr_out[3] = (|(tag_retire_pipes_cpsr[3]) | (tag_change_pipes_cpsr[3] & 
(~(|tag_change_selector_for_cpsr_final_specu_alu_pipe1) | (new_tag_instr_complete_for_cpsr_alu_pipe1 & 
(~new_tag_speculative_instr_for_cpsr_alu_pipe1 | new_tag_speculative_result_for_cpsr_alu_pipe1)))));
assign tag_retire_pipes_for_cpsr_out[2] = (|(tag_retire_pipes_cpsr[2]) | (tag_change_pipes_cpsr[2] & 
(~(|tag_change_selector_for_cpsr_final_specu_alu_pipe2) | (new_tag_instr_complete_for_cpsr_alu_pipe2 & 
(~new_tag_speculative_instr_for_cpsr_alu_pipe2 | new_tag_speculative_result_for_cpsr_alu_pipe2)))));
assign tag_retire_pipes_for_cpsr_out[1] = (|(tag_retire_pipes_cpsr[1]) | (tag_change_pipes_cpsr[1] & 
(~(|tag_change_selector_for_cpsr_final_specu_load_store_pipe3) | 
(new_tag_instr_complete_for_cpsr_load_store_pipe3 & 
(~new_tag_speculative_instr_for_cpsr_load_store_pipe3 | 
new_tag_speculative_result_for_cpsr_load_store_pipe3)))));
assign tag_retire_pipes_for_cpsr_out[0] = (|(tag_retire_pipes_cpsr[0]) | (tag_change_pipes_cpsr[0] & 
(~(|tag_change_selector_for_cpsr_final_specu_branch_pipe4) | 
(new_tag_instr_complete_for_cpsr_branch_pipe4 & (~new_tag_speculative_instr_for_cpsr_branch_pipe4 | 
new_tag_speculative_result_for_cpsr_branch_pipe4)))));
/******CPSR_ENDS******/
/******TAG_RETIRE_ENDS******/

/******TAG_CHANGE_STARTS******/
/******RD_STARTS******/
assign tag_change_pipes_for_rd_out[3] = (|(tag_change_pipes_rd[3])) & 
(|tag_change_selector_for_rd_final_specu_alu_pipe1);
assign tag_change_pipes_for_rd_out[2] = (|(tag_change_pipes_rd[2])) &
(|tag_change_selector_for_rd_final_specu_alu_pipe2);
assign tag_change_pipes_for_rd_out[1] = (|(tag_change_pipes_rd[1])) &
(|tag_change_selector_for_rd_final_specu_load_store_pipe3);
assign tag_change_pipes_for_rd_out[0] = (|(tag_change_pipes_rd[0])) &
(|tag_change_selector_for_rd_final_specu_branch_pipe4);
/******RD_ENDS******/
/******RN_STARTS******/
assign tag_change_pipes_for_rn_out[3] = (|(tag_change_pipes_rn[3])) & 
(|tag_change_selector_for_rn_final_specu_alu_pipe1);
assign tag_change_pipes_for_rn_out[2] = (|(tag_change_pipes_rn[2])) &
(|tag_change_selector_for_rn_final_specu_alu_pipe2);
assign tag_change_pipes_for_rn_out[1] = (|(tag_change_pipes_rn[1])) &
(|tag_change_selector_for_rn_final_specu_load_store_pipe3);
assign tag_change_pipes_for_rn_out[0] = (|(tag_change_pipes_rn[0])) &
(|tag_change_selector_for_rn_final_specu_branch_pipe4);
/******RN_ENDS******/
/******CPSR_STARTS******/
assign tag_change_pipes_for_cpsr_out[3] = (|(tag_change_pipes_cpsr[3])) & 
(|tag_change_selector_for_cpsr_final_specu_alu_pipe1);
assign tag_change_pipes_for_cpsr_out[2] = (|(tag_change_pipes_cpsr[2])) &
(|tag_change_selector_for_cpsr_final_specu_alu_pipe2);
assign tag_change_pipes_for_cpsr_out[1] = (|(tag_change_pipes_cpsr[1])) &
(|tag_change_selector_for_cpsr_final_specu_load_store_pipe3);
assign tag_change_pipes_for_cpsr_out[0] = (|(tag_change_pipes_cpsr[0])) &
(|tag_change_selector_for_cpsr_final_specu_branch_pipe4);
/******CPSR_ENDS******/
/******TAG_CHANGE_ENDS******/

/******TAG_CHANGE_DUE_TO_SPECULATIVE_INSTR_STARTS******/
tag_change_selector_specu tag_change_selector_alu_pipe1 (
	.tag_change_pipe_in(tag_change_pipes[3]),
	.tag_to_change_selector_out(tag_change_selector_specu_alu_pipe1)
	);
tag_change_selector_specu tag_change_selector_alu_pipe2 (
	.tag_change_pipe_in(tag_change_pipes[2]),
	.tag_to_change_selector_out(tag_change_selector_specu_alu_pipe2)
	);
tag_change_selector_specu tag_change_selector_load_store_pipe3 (
	.tag_change_pipe_in(tag_change_pipes[1]),
	.tag_to_change_selector_out(tag_change_selector_specu_load_store_pipe3)
	);																	
tag_change_selector_specu tag_change_selector_branch_pipe4 (
	.tag_change_pipe_in(tag_change_pipes[0]),
	.tag_to_change_selector_out(tag_change_selector_specu_branch_pipe4)
	);

genvar q;
generate
for(q=0;q<=`REORDER_BUFFER_SIZE-1;q=q+1)
begin : grp_rd_rn_addr_match_assign
	/******RD_ADDR_MATCH_STARTS******/
	assign rd_addr_match_for_tag_change_specu_alu_pipe1[q] = 
	((~(|(rd_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE1_STARTS:`REG_ADDR_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE]) | 
	(~(|(rd_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE1_STARTS:`REG_ADDR_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rd_addr_match_for_tag_change_specu_alu_pipe2[q] = 
	((~(|(rd_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE2_STARTS:`REG_ADDR_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE]) | 
	(~(|(rd_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE2_STARTS:`REG_ADDR_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rd_addr_match_for_tag_change_specu_load_store_pipe3[q] = 
	((~(|(rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE]) | 
	(~(|(rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rd_addr_match_for_tag_change_specu_branch_pipe4[q] = 
	((~(|(rd_addr_pipes_combined_in[`REG_ADDR_BRANCH_PIPE4_STARTS:`REG_ADDR_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE]) | 
	(~(|(rd_addr_pipes_combined_in[`REG_ADDR_BRANCH_PIPE4_STARTS:`REG_ADDR_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	/******RD_ADDR_MATCH_ENDS******/
	
	/******RN_ADDR_MATCH_STARTS******/
	assign rn_addr_match_for_tag_change_specu_alu_pipe1[q] = 
	((~(|(rn_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE1_STARTS:`REG_ADDR_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE]) | 
	(~(|(rn_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE1_STARTS:`REG_ADDR_ALU_PIPE1_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE]))	& 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rn_addr_match_for_tag_change_specu_alu_pipe2[q] = 
	((~(|(rn_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE2_STARTS:`REG_ADDR_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE]) | 
	(~(|(rn_addr_pipes_combined_in[`REG_ADDR_ALU_PIPE2_STARTS:`REG_ADDR_ALU_PIPE2_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rn_addr_match_for_tag_change_specu_load_store_pipe3[q] = 
	((~(|(rn_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE]) | 
	(~(|(rn_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	assign rn_addr_match_for_tag_change_specu_branch_pipe4[q] = 
	((~(|(rn_addr_pipes_combined_in[`REG_ADDR_BRANCH_PIPE4_STARTS:`REG_ADDR_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[q][`RB_RN_ADDR_START:`RB_RN_ADDR_END])) & reorder_buffer[q][`RB_RN_UPDATE]) | 
	(~(|(rn_addr_pipes_combined_in[`REG_ADDR_BRANCH_PIPE4_STARTS:`REG_ADDR_BRANCH_PIPE4_ENDS] ^ 
	reorder_buffer[q][`RB_RD_ADDR_START:`RB_RD_ADDR_END])) & reorder_buffer[q][`RB_RD_UPDATE])) & 
	reorder_buffer_position_occupied[q] & (~instr_complete_data[q] | 
	~reorder_buffer[q][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[q]);
	/******RD_ADDR_MATCH_ENDS******/
	
end
endgenerate
	
/******TAG_CHANGE_FINAL_SELECTOR_STARTS******/
/******RD_STARTS******/
assign tag_change_selector_for_rd_final_specu_alu_pipe1 = rd_addr_match_for_tag_change_specu_alu_pipe1
& tag_change_selector_specu_alu_pipe1;
assign tag_change_selector_for_rd_final_specu_alu_pipe2 = rd_addr_match_for_tag_change_specu_alu_pipe2
& tag_change_selector_specu_alu_pipe2;
assign tag_change_selector_for_rd_final_specu_load_store_pipe3 = 
rd_addr_match_for_tag_change_specu_load_store_pipe3 & tag_change_selector_specu_load_store_pipe3;
assign tag_change_selector_for_rd_final_specu_branch_pipe4 = 
rd_addr_match_for_tag_change_specu_branch_pipe4 & tag_change_selector_specu_branch_pipe4;
/******RD_ENDS******/
/******RN_STARTS******/
assign tag_change_selector_for_rn_final_specu_alu_pipe1 = rn_addr_match_for_tag_change_specu_alu_pipe1
& tag_change_selector_specu_alu_pipe1;
assign tag_change_selector_for_rn_final_specu_alu_pipe2 = rn_addr_match_for_tag_change_specu_alu_pipe2
& tag_change_selector_specu_alu_pipe2;
assign tag_change_selector_for_rn_final_specu_load_store_pipe3 = 
rn_addr_match_for_tag_change_specu_load_store_pipe3 & tag_change_selector_specu_load_store_pipe3;
assign tag_change_selector_for_rn_final_specu_branch_pipe4 = 
rn_addr_match_for_tag_change_specu_branch_pipe4 & tag_change_selector_specu_branch_pipe4;
/******RN_ENDS******/
/******CPSR_STARTS******/
assign tag_change_selector_for_cpsr_final_specu_alu_pipe1 = cpsr_update_by_pipes & 
tag_change_selector_specu_alu_pipe1;
assign tag_change_selector_for_cpsr_final_specu_alu_pipe2 = cpsr_update_by_pipes & 
tag_change_selector_specu_alu_pipe2;
assign tag_change_selector_for_cpsr_final_specu_load_store_pipe3 = cpsr_update_by_pipes & 
tag_change_selector_specu_load_store_pipe3;
assign tag_change_selector_for_cpsr_final_specu_branch_pipe4 = cpsr_update_by_pipes & 
tag_change_selector_specu_branch_pipe4;
/******CPSR_ENDS******/
/******TAG_CHANGE_FINAL_SELECTOR_STARTS******/

/******PRIORITY_ENCODER_FOR_TAG_CHANGE_STARTS******/
/******RD_STARTS******/
assign {tag_to_change_specu_for_rd_out[`TAG_BITS_ALU_PIPE1_STARTS:`TAG_BITS_ALU_PIPE1_ENDS],
new_tag_instr_complete_for_rd_alu_pipe1,new_tag_speculative_instr_for_rd_alu_pipe1,
new_tag_speculative_result_for_rd_alu_pipe1} = (tag_change_selector_for_rd_final_specu_alu_pipe1[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rd_final_specu_alu_pipe1[13] ? {reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[13],reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[12] ? {reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[12],reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[11] ? {reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[11],reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[10] ? {reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[10],reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[9] ? {reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[9],reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[8] ? {reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[8],reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[7] ? {reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[7],reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[6] ? {reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[6],reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[5] ? {reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[5],reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[4] ? {reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[4],reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[3] ? {reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[3],reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[2] ? {reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[2],reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[1] ? {reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[1],reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rd_final_specu_alu_pipe1[0] ? {reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[0],reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rd_out[`TAG_BITS_ALU_PIPE2_STARTS:`TAG_BITS_ALU_PIPE2_ENDS],
new_tag_instr_complete_for_rd_alu_pipe2,new_tag_speculative_instr_for_rd_alu_pipe2,
new_tag_speculative_result_for_rd_alu_pipe2} = (tag_change_selector_for_rd_final_specu_alu_pipe2[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rd_final_specu_alu_pipe2[13] ? {reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[13],reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[12] ? {reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[12],reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[11] ? {reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[11],reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[10] ? {reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[10],reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[9] ? {reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[9],reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[8] ? {reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[8],reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[7] ? {reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[7],reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[6] ? {reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[6],reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[5] ? {reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[5],reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[4] ? {reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[4],reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[3] ? {reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[3],reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[2] ? {reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[2],reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[1] ? {reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[1],reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rd_final_specu_alu_pipe2[0] ? {reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[0],reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rd_out[`TAG_BITS_LOAD_STORE_PIPE3_STARTS:`TAG_BITS_LOAD_STORE_PIPE3_ENDS],
new_tag_instr_complete_for_rd_load_store_pipe3,new_tag_speculative_instr_for_rd_load_store_pipe3,
new_tag_speculative_result_for_rd_load_store_pipe3} = 
(tag_change_selector_for_rd_final_specu_load_store_pipe3[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rd_final_specu_load_store_pipe3[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rd_final_specu_load_store_pipe3[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rd_out[`TAG_BITS_BRANCH_PIPE4_STARTS:`TAG_BITS_BRANCH_PIPE4_ENDS],
new_tag_instr_complete_for_rd_branch_pipe4,new_tag_speculative_instr_for_rd_branch_pipe4,
new_tag_speculative_result_for_rd_branch_pipe4} = 
(tag_change_selector_for_rd_final_specu_branch_pipe4[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rd_final_specu_branch_pipe4[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rd_final_specu_branch_pipe4[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));
/******RD_ENDS******/
/******RN_STARTS******/
assign {tag_to_change_specu_for_rn_out[`TAG_BITS_ALU_PIPE1_STARTS:`TAG_BITS_ALU_PIPE1_ENDS],
new_tag_instr_complete_for_rn_alu_pipe1,new_tag_speculative_instr_for_rn_alu_pipe1,
new_tag_speculative_result_for_rn_alu_pipe1} = (tag_change_selector_for_rn_final_specu_alu_pipe1[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rn_final_specu_alu_pipe1[13] ? {reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[13],reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[12] ? {reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[12],reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[11] ? {reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[11],reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[10] ? {reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[10],reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[9] ? {reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[9],reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[8] ? {reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[8],reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[7] ? {reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[7],reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[6] ? {reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[6],reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[5] ? {reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[5],reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[4] ? {reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[4],reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[3] ? {reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[3],reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[2] ? {reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[2],reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[1] ? {reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[1],reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rn_final_specu_alu_pipe1[0] ? {reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[0],reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rn_out[`TAG_BITS_ALU_PIPE2_STARTS:`TAG_BITS_ALU_PIPE2_ENDS],
new_tag_instr_complete_for_rn_alu_pipe2,new_tag_speculative_instr_for_rn_alu_pipe2,
new_tag_speculative_result_for_rn_alu_pipe2} = (tag_change_selector_for_rn_final_specu_alu_pipe2[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rn_final_specu_alu_pipe2[13] ? {reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[13],reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[12] ? {reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[12],reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[11] ? {reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[11],reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[10] ? {reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[10],reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[9] ? {reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[9],reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[8] ? {reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[8],reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[7] ? {reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[7],reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[6] ? {reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[6],reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[5] ? {reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[5],reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[4] ? {reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[4],reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[3] ? {reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[3],reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[2] ? {reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[2],reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[1] ? {reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[1],reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rn_final_specu_alu_pipe2[0] ? {reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],
instr_complete_data[0],reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rn_out[`TAG_BITS_LOAD_STORE_PIPE3_STARTS:`TAG_BITS_LOAD_STORE_PIPE3_ENDS],
new_tag_instr_complete_for_rn_load_store_pipe3,new_tag_speculative_instr_for_rn_load_store_pipe3,
new_tag_speculative_result_for_rn_load_store_pipe3} = 
(tag_change_selector_for_rn_final_specu_load_store_pipe3[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rn_final_specu_load_store_pipe3[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rn_final_specu_load_store_pipe3[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_rn_out[`TAG_BITS_BRANCH_PIPE4_STARTS:`TAG_BITS_BRANCH_PIPE4_ENDS],
new_tag_instr_complete_for_rn_branch_pipe4,new_tag_speculative_instr_for_rn_branch_pipe4,
new_tag_speculative_result_for_rn_branch_pipe4} = 
(tag_change_selector_for_rn_final_specu_branch_pipe4[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_rn_final_specu_branch_pipe4[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_rn_final_specu_branch_pipe4[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));
/******RN_ENDS******/
/******CPSR_STARTS******/
assign {tag_to_change_specu_for_cpsr_out[`TAG_BITS_ALU_PIPE1_STARTS:`TAG_BITS_ALU_PIPE1_ENDS],
new_tag_instr_complete_for_cpsr_alu_pipe1,new_tag_speculative_instr_for_cpsr_alu_pipe1,
new_tag_speculative_result_for_cpsr_alu_pipe1} = 
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe1[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_cpsr_out[`TAG_BITS_ALU_PIPE2_STARTS:`TAG_BITS_ALU_PIPE2_ENDS],
new_tag_instr_complete_for_cpsr_alu_pipe2,new_tag_speculative_instr_for_cpsr_alu_pipe2,
new_tag_speculative_result_for_cpsr_alu_pipe2} = 
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_cpsr_final_specu_alu_pipe2[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_cpsr_out[`TAG_BITS_LOAD_STORE_PIPE3_STARTS:
`TAG_BITS_LOAD_STORE_PIPE3_ENDS],new_tag_instr_complete_for_cpsr_load_store_pipe3,
new_tag_speculative_instr_for_cpsr_load_store_pipe3,
new_tag_speculative_result_for_cpsr_load_store_pipe3} = 
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_cpsr_final_specu_load_store_pipe3[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));

assign {tag_to_change_specu_for_cpsr_out[`TAG_BITS_BRANCH_PIPE4_STARTS:`TAG_BITS_BRANCH_PIPE4_ENDS],
new_tag_instr_complete_for_cpsr_branch_pipe4,new_tag_speculative_instr_for_cpsr_branch_pipe4,
new_tag_speculative_result_for_cpsr_branch_pipe4} = 
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[14] ? 
{reorder_buffer[14][`RB_TAG_START:`RB_TAG_END],instr_complete_data[14],
reorder_buffer[14][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[14]} : 
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[13] ? 
{reorder_buffer[13][`RB_TAG_START:`RB_TAG_END],instr_complete_data[13],
reorder_buffer[13][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[13]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[12] ? 
{reorder_buffer[12][`RB_TAG_START:`RB_TAG_END],instr_complete_data[12],
reorder_buffer[12][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[12]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[11] ? 
{reorder_buffer[11][`RB_TAG_START:`RB_TAG_END],instr_complete_data[11],
reorder_buffer[11][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[11]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[10] ? 
{reorder_buffer[10][`RB_TAG_START:`RB_TAG_END],instr_complete_data[10],
reorder_buffer[10][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[10]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[9] ? 
{reorder_buffer[9][`RB_TAG_START:`RB_TAG_END],instr_complete_data[9],
reorder_buffer[9][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[9]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[8] ? 
{reorder_buffer[8][`RB_TAG_START:`RB_TAG_END],instr_complete_data[8],
reorder_buffer[8][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[8]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[7] ? 
{reorder_buffer[7][`RB_TAG_START:`RB_TAG_END],instr_complete_data[7],
reorder_buffer[7][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[7]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[6] ? 
{reorder_buffer[6][`RB_TAG_START:`RB_TAG_END],instr_complete_data[6],
reorder_buffer[6][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[6]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[5] ? 
{reorder_buffer[5][`RB_TAG_START:`RB_TAG_END],instr_complete_data[5],
reorder_buffer[5][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[5]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[4] ? 
{reorder_buffer[4][`RB_TAG_START:`RB_TAG_END],instr_complete_data[4],
reorder_buffer[4][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[4]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[3] ? 
{reorder_buffer[3][`RB_TAG_START:`RB_TAG_END],instr_complete_data[3],
reorder_buffer[3][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[3]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[2] ? 
{reorder_buffer[2][`RB_TAG_START:`RB_TAG_END],instr_complete_data[2],
reorder_buffer[2][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[2]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[1] ? 
{reorder_buffer[1][`RB_TAG_START:`RB_TAG_END],instr_complete_data[1],
reorder_buffer[1][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[1]} :
(tag_change_selector_for_cpsr_final_specu_branch_pipe4[0] ? 
{reorder_buffer[0][`RB_TAG_START:`RB_TAG_END],instr_complete_data[0],
reorder_buffer[0][`RB_CPSR_SPECULATIVE_INSTR],speculative_instr_data[0]} :
{`TAG_BITS_SIZE'b0000,1'b0,1'b0,1'b0})))))))))))))));
/******RN_ENDS******/
/******PRIORITY_ENCODER_FOR_TAG_CHANGE_ENDS******/

/******TAG_CHANGE_DUE_TO_SPECULATIVE_INSTR_ENDS******/

/******LDM_STM_DATA_STARTS******/
assign ldm_stm_data_en[0] = reg_update_ldm_stm_in & |en_reg_ldm_stm_data_en;

genvar r;
generate
for(r=0;r<`LDM_STM_REG_SIZE-1;r=r+1)
begin : grp_assign_ldm_stm_data_en
	
	register_with_reset #1 reg_ldm_stm_data_en (
		 .data_in(ldm_stm_data_en[r]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(|en_reg_ldm_stm_data_en), 
		 .data_out(ldm_stm_data_en_temp[r])
		 );
	assign ldm_stm_data_en[r+1] = ldm_stm_data_en_temp[r] & |en_reg_ldm_stm_data_en;
end
endgenerate

genvar s;
generate
for(s=0;s<=`LDM_STM_REG_SIZE-1;s=s+1)
begin : grp_assign_ldm_stm_data_data
	assign en_reg_ldm_stm_data_en[s] = ldm_stall_in & 
	tag_matched_for_instr_complete_load_store_pipe3[s] & 
	reorder_buffer[s][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] & 
	(~reorder_buffer[s][`RB_CPSR_SPECULATIVE_INSTR] | speculative_instr_data[s]);
	

	
	register_with_reset #`LDM_STM_DATA_SIZE reg_ldm_stm_data (
		 .data_in(data_to_ldm_stm_data[s]), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(ldm_stm_data_en[s] | ldm_stm_retire), 
		 .data_out(ldm_stm_data[s])
		 );
end
endgenerate

genvar t;
generate
for(t=0;t<=`LDM_STM_REG_SIZE-5;t=t+1)
begin : grp_assign_data_to_ldm_stm_data
	assign data_to_ldm_stm_data[t] = ldm_stm_retire ? ldm_stm_data[t+4] : {ldm_stall_in,
	rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS],
	rd_data_pipes_in[63:32]};
end
endgenerate

assign data_to_ldm_stm_data[`LDM_STM_REG_SIZE-4] = ldm_stm_retire ? 37'b0 : {ldm_stall_in,
rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS],
rd_data_pipes_in[63:32]};
assign data_to_ldm_stm_data[`LDM_STM_REG_SIZE-3] = ldm_stm_retire ? 37'b0 : {ldm_stall_in,
rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS],
rd_data_pipes_in[63:32]};
assign data_to_ldm_stm_data[`LDM_STM_REG_SIZE-2] = ldm_stm_retire ? 37'b0 : {ldm_stall_in,
rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS],
rd_data_pipes_in[63:32]};
assign data_to_ldm_stm_data[`LDM_STM_REG_SIZE-1] = ldm_stm_retire ? 37'b0 : {ldm_stall_in,
rd_addr_pipes_combined_in[`REG_ADDR_LOAD_STORE_PIPE3_STARTS:`REG_ADDR_LOAD_STORE_PIPE3_ENDS],
rd_data_pipes_in[63:32]};
/******LDM_STM_DATA_ENDS******/

/******INSTRUCTION_RETIRE_STARTS******/
assign reorder_buffer_shift = (instr_complete_data[0] & ((~instr_complete_data[1] & 
~reorder_buffer[0][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR]) | ~ldm_stm_retire));
assign reorder_buffer_shift_2 = instr_complete_data[1] & instr_complete_data[0] & 
~(reorder_buffer[1][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR]);
assign ldm_stm_retire = reorder_buffer[0][`RB_LOAD_STORE_MULTIPLE_TYPE_INSTR] & instr_complete_data[0]
& (ldm_stm_data[0][`LDM_STM_DATA_ENABLE] & ldm_stm_data[1][`LDM_STM_DATA_ENABLE] & 
ldm_stm_data[2][`LDM_STM_DATA_ENABLE] & ldm_stm_data[3][`LDM_STM_DATA_ENABLE]);
/******INSTRUCTION_RETIRE_ENDS******/

/******INSTRUCTION_DATA_STARTS******/
assign data_retire_out[`DATA_RETIRE_PORT1_STARTS:`DATA_RETIRE_PORT1_ENDS] = ldm_stm_retire ? 
ldm_stm_data[0][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] : rd_data[0];
assign data_retire_out[`DATA_RETIRE_PORT2_STARTS:`DATA_RETIRE_PORT2_ENDS] = ldm_stm_retire ? 
ldm_stm_data[1][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] : rn_data[0];
assign data_retire_out[`DATA_RETIRE_PORT3_STARTS:`DATA_RETIRE_PORT3_ENDS] = ldm_stm_retire ? 
ldm_stm_data[2][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] : rd_data[1];
assign data_retire_out[`DATA_RETIRE_PORT4_STARTS:`DATA_RETIRE_PORT4_ENDS] = ldm_stm_retire ? 
ldm_stm_data[3][`LDM_STM_DATA_RD_DATA_STARTS:`LDM_STM_DATA_RD_DATA_ENDS] : rn_data[1];
/******INSTRUCTION_DATA_ENDS******/

/******INSTRUCTION_RETIRE_WRITE_EN_STARTS******/
assign data_retire_write_en_out[`RETIRE_EN_PORT1] = instr_complete_data[0] & 
(reorder_buffer[0][`RB_RD_UPDATE] | ldm_stm_retire);
assign data_retire_write_en_out[`RETIRE_EN_PORT2] = instr_complete_data[0] & 
(reorder_buffer[0][`RB_RN_UPDATE] | ldm_stm_retire);
assign data_retire_write_en_out[`RETIRE_EN_PORT3] = instr_complete_data[0] & (ldm_stm_retire | 
(instr_complete_data[1] & reorder_buffer[1][`RB_RD_UPDATE]));
assign data_retire_write_en_out[`RETIRE_EN_PORT4] = instr_complete_data[0] & (ldm_stm_retire | 
(instr_complete_data[1] & reorder_buffer[1][`RB_RN_UPDATE]));
/******INSTRUCTION_RETIRE_WRITE_EN_ENDS******/

endmodule
