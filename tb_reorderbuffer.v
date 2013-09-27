`include "timescale.v"
`include "reorder_buffer_define.v"

module tb_reorderbuffer;

	// Inputs
	reg clk_in;
	reg reset_in;
	reg [`RB_NEW_ENTRY_WORD_SIZE-1:0] new_entry_word1_in;
	reg [`RB_NEW_ENTRY_WORD_SIZE-1:0] new_entry_word2_in;
	reg reorder_buffer_update_in;
	reg [31:0] rd_data_alu_pipe1_in;
	reg [31:0] rd_data_alu_pipe2_in;
	reg [31:0] rd_data_load_store_pipe3_in;
	reg [31:0] rd_data_branch_pipe4_in;
	reg [31:0] rn_data_alu_pipe1_in; 
	reg [31:0] rn_data_alu_pipe2_in;
	reg [31:0] rn_data_load_store_pipe3_in;
	reg [31:0] rn_data_branch_pipe4_in;
	reg [31:0] cpsr_data_alu_pipe1_in;
	reg [31:0] cpsr_data_alu_pipe2_in;
	reg [31:0] cpsr_data_load_store_pipe3_in;
	reg [31:0] cpsr_data_branch_pipe4_in;
	reg [`TAG_BITS_ALL_PIPES_COMBINED-1:0] tag_bits_pipes_combined_in;
	reg [3:0] instr_complete_frm_pipes_in;
	reg [`TAG_RD_ISSUE-1:0] tag_bits_for_rd_to_issue_in;  
	reg [`RD_ADDR_ISSUE-1:0] rd_addr_to_issue_in;
	reg [`TAG_RN_ISSUE-1:0] tag_bits_for_rn_to_issue_in;
	reg [`RN_ADDR_ISSUE-1:0] rn_addr_to_issue_in; 
	reg [`TAG_RM_ISSUE-1:0] tag_bits_for_rm_to_issue_in; 
	reg [`RM_ADDR_ISSUE-1:0] rm_addr_to_issue_in; 
	reg [`TAG_RS_ISSUE-1:0] tag_bits_for_rs_to_issue_in; 
	reg [`RS_ADDR_ISSUE-1:0] rs_addr_to_issue_in; 
	reg [`TAG_CPSR_ISSUE-1:0] tag_bits_for_cpsr_to_issue_in; 
	reg [3:0] speculative_result_in;
	reg [`REG_ADDR_PIPES_COMBINED-1:0] rd_addr_pipes_combined_in; 
	reg [`REG_ADDR_PIPES_COMBINED-1:0] rn_addr_pipes_combined_in;
	reg ldm_stall_in;
	reg reg_update_ldm_stm_in;
	reg [`RD_DATA_PIPES-1:0] rd_data_issue_pipes_frm_reg_file_in; 
	reg [`RN_DATA_PIPES-1:0] rn_data_issue_pipes_frm_reg_file_in; 
	reg [`RM_DATA_PIPES-1:0] rm_data_issue_pipes_frm_reg_file_in;
	reg [`RS_DATA_PIPES-1:0] rs_data_issue_pipes_frm_reg_file_in;
	reg [31:0] cpsr_data_issue_pipes_frm_reg_file_in;
	
	

	// Outputs
	wire [`TAG_BITS_SIZE-1:0] reorder_buffer_status_out; 
	wire [31:0] rd_data_to_pipes_out;
	wire [31:0] rn_data_to_issue_alu_pipe1_out,rn_data_to_issue_alu_pipe2_out;
	wire [31:0] rn_data_to_issue_load_store_pipe3_out;
	wire [31:0] rm_data_to_issue_alu_pipe1_out,rm_data_to_issue_alu_pipe2_out;
	wire [31:0] rm_data_to_issue_load_store_pipe3_out,rm_data_to_issue_branch_pipe4_out;
	wire [31:0] rs_data_to_issue_alu_pipe1_out,rs_data_to_issue_alu_pipe2_out;
	wire [31:0] rs_data_to_issue_load_store_pipe3_out;
	wire [31:0] cpsr_data_to_issue_alu_pipe1_out,cpsr_data_to_issue_alu_pipe2_out;
	wire [31:0] cpsr_data_to_issue_load_store_pipe3_out,cpsr_data_to_issue_branch_pipe4_out;
	wire [3:0] tag_retire_pipes_for_rd_out;
	wire [3:0] tag_retire_pipes_for_rn_out;
	wire [3:0] tag_retire_pipes_for_cpsr_out;
	wire [3:0] tag_change_pipes_for_rd_out;
	wire [3:0] tag_change_pipes_for_rn_out;
	wire [3:0] tag_change_pipes_for_cpsr_out;
	wire [3:0] tag_to_change_specu_for_rd_alu_pipe1_out;
	wire [3:0] tag_to_change_specu_for_rd_alu_pipe2_out;
	wire [3:0] tag_to_change_specu_load_store_for_rd_pipe3_out;
	wire [3:0] tag_to_change_specu_for_rd_branch_pipe4_out;
	wire [3:0] tag_to_change_specu_for_rn_alu_pipe1_out;
	wire [3:0] tag_to_change_specu_for_rn_alu_pipe2_out;
	wire [3:0] tag_to_change_specu_load_store_for_rn_pipe3_out;
	wire [3:0] tag_to_change_specu_for_rn_branch_pipe4_out;
	wire [3:0] tag_to_change_specu_for_cpsr_alu_pipe1_out;
	wire [3:0] tag_to_change_specu_for_cpsr_alu_pipe2_out;
	wire [3:0] tag_to_change_specu_load_store_for_cpsr_pipe3_out;
	wire [3:0] tag_to_change_specu_for_cpsr_branch_pipe4_out;
	wire [31:0] data_port1_out,data_port2_out,data_port3_out,data_port4_out;
	wire [3:0] data_retire_write_en_out;

	// Instantiate the Unit Under Test (UUT)
	reorder_buffer instance_name (
    .clk_in(clk_in), 
    .reset_in(reset_in), 
    .new_entry_word1_in(new_entry_word1_in), 
    .new_entry_word2_in(new_entry_word2_in), 
    .reorder_buffer_update_in(reorder_buffer_update_in), 
    .rd_data_pipes_in({rd_data_alu_pipe1_in,rd_data_alu_pipe2_in,rd_data_load_store_pipe3_in,
	 rd_data_branch_pipe4_in}), 
    .rn_data_pipes_in({rn_data_alu_pipe1_in,rn_data_alu_pipe2_in,rn_data_load_store_pipe3_in,
	 rn_data_branch_pipe4_in}), 
    .cpsr_data_pipes_in({cpsr_data_alu_pipe1_in,cpsr_data_alu_pipe2_in,cpsr_data_load_store_pipe3_in,
	 cpsr_data_branch_pipe4_in}), 
    .tag_bits_pipes_combined_in(tag_bits_pipes_combined_in), 
	 .rd_addr_pipes_combined_in(rd_addr_pipes_combined_in),
	 .rn_addr_pipes_combined_in(rn_addr_pipes_combined_in),
    .instr_complete_frm_pipes_in(instr_complete_frm_pipes_in), 
	 .tag_bits_for_rd_to_issue_in(tag_bits_for_rd_to_issue_in), 
    .rd_addr_to_issue_in(rd_addr_to_issue_in), 
    .tag_bits_for_rn_to_issue_in(tag_bits_for_rn_to_issue_in), 
    .rn_addr_to_issue_in(rn_addr_to_issue_in), 
    .tag_bits_for_rm_to_issue_in(tag_bits_for_rm_to_issue_in), 
    .rm_addr_to_issue_in(rm_addr_to_issue_in), 
    .tag_bits_for_rs_to_issue_in(tag_bits_for_rs_to_issue_in), 
    .rs_addr_to_issue_in(rs_addr_to_issue_in), 
    .tag_bits_for_cpsr_to_issue_in(tag_bits_for_cpsr_to_issue_in),
	 .speculative_result_in(speculative_result_in),
	 .ldm_stall_in(ldm_stall_in),
	 .reg_update_ldm_stm_in(reg_update_ldm_stm_in),
	 .rd_data_issue_pipes_frm_reg_file_in(rd_data_issue_pipes_frm_reg_file_in),
	 .rn_data_issue_pipes_frm_reg_file_in(rn_data_issue_pipes_frm_reg_file_in),
	 .rm_data_issue_pipes_frm_reg_file_in(rm_data_issue_pipes_frm_reg_file_in),
	 .rs_data_issue_pipes_frm_reg_file_in(rs_data_issue_pipes_frm_reg_file_in),
	 .cpsr_data_issue_pipes_frm_reg_file_in(cpsr_data_issue_pipes_frm_reg_file_in),
    .reorder_buffer_status_out(reorder_buffer_status_out),
	 .rd_data_to_pipes_out(rd_data_to_pipes_out), 
    .rn_data_to_issue_pipes_out({rn_data_to_issue_alu_pipe1_out,rn_data_to_issue_alu_pipe2_out,
	 rn_data_to_issue_load_store_pipe3_out}), 
    .rm_data_to_issue_pipes_out({rm_data_to_issue_alu_pipe1_out,rm_data_to_issue_alu_pipe2_out,
	 rm_data_to_issue_load_store_pipe3_out,rm_data_to_issue_branch_pipe4_out}), 
    .rs_data_to_issue_pipes_out({rs_data_to_issue_alu_pipe1_out,rs_data_to_issue_alu_pipe2_out,
	 rs_data_to_issue_load_store_pipe3_out}), 
    .cpsr_data_to_issue_pipes_out({cpsr_data_to_issue_alu_pipe1_out,cpsr_data_to_issue_alu_pipe2_out,
	 cpsr_data_to_issue_load_store_pipe3_out,cpsr_data_to_issue_branch_pipe4_out}),
	 .tag_retire_pipes_for_rd_out(tag_retire_pipes_for_rd_out),
	 .tag_retire_pipes_for_rn_out(tag_retire_pipes_for_rn_out),
	 .tag_retire_pipes_for_cpsr_out(tag_retire_pipes_for_cpsr_out),
	 .tag_change_pipes_for_rd_out(tag_change_pipes_for_rd_out),
	 .tag_change_pipes_for_rn_out(tag_change_pipes_for_rn_out),
	 .tag_change_pipes_for_cpsr_out(tag_change_pipes_for_cpsr_out),
	 .tag_to_change_specu_for_rd_out({tag_to_change_specu_for_rd_alu_pipe1_out,
	 tag_to_change_specu_for_rd_alu_pipe2_out,tag_to_change_specu_load_store_for_rd_pipe3_out,
	 tag_to_change_specu_for_rd_branch_pipe4_out}),
	 .tag_to_change_specu_for_rn_out({tag_to_change_specu_for_rn_alu_pipe1_out,
	 tag_to_change_specu_for_rn_alu_pipe2_out,tag_to_change_specu_load_store_for_rn_pipe3_out,
	 tag_to_change_specu_for_rn_branch_pipe4_out}),
	 .tag_to_change_specu_for_cpsr_out({tag_to_change_specu_for_cpsr_alu_pipe1_out,
	 tag_to_change_specu_for_cpsr_alu_pipe2_out,tag_to_change_specu_load_store_for_cpsr_pipe3_out,
	 tag_to_change_specu_for_cpsr_branch_pipe4_out}),
	 .data_retire_out({data_port1_out,data_port2_out,data_port3_out,data_port4_out}),
	 .data_retire_write_en_out(data_retire_write_en_out)
    );

	initial begin
		// Initialize Inputs
		clk_in <= 1'b0;
		reset_in <= 1'b1;
		new_entry_word1_in <= 0;
		new_entry_word2_in <= 0;
		reorder_buffer_update_in <= 0;
		rd_data_alu_pipe1_in <= 0;
	   rd_data_alu_pipe2_in <= 0;
	   rd_data_load_store_pipe3_in <= 0;
	   rd_data_branch_pipe4_in <= 0;
	   rn_data_alu_pipe1_in <= 0;
	   rn_data_alu_pipe2_in <= 0;
	   rn_data_load_store_pipe3_in <= 0;
	   rn_data_branch_pipe4_in <= 0;
	   cpsr_data_alu_pipe1_in <= 0;
	   cpsr_data_alu_pipe2_in <= 0;
	   cpsr_data_load_store_pipe3_in <= 0;
	   cpsr_data_branch_pipe4_in <= 0;
	   tag_bits_pipes_combined_in <= 0;
	   instr_complete_frm_pipes_in <= 0;
		tag_bits_for_rd_to_issue_in <= 0;
		rd_addr_to_issue_in <= 0;
		tag_bits_for_rn_to_issue_in <= 0;
		rn_addr_to_issue_in <= 0;
		tag_bits_for_rm_to_issue_in <= 0;
		rm_addr_to_issue_in <= 0;
		tag_bits_for_rs_to_issue_in <= 0;
		rs_addr_to_issue_in <= 0;
		tag_bits_for_cpsr_to_issue_in <= 0;
		speculative_result_in <= 0;
		rd_addr_pipes_combined_in <= 0;
		rn_addr_pipes_combined_in <= 0;
		ldm_stall_in <= 0;
		reg_update_ldm_stm_in <= 0;
		rd_data_issue_pipes_frm_reg_file_in <= 0;
		rn_data_issue_pipes_frm_reg_file_in <= 0;
		rm_data_issue_pipes_frm_reg_file_in <= 0;
		rs_data_issue_pipes_frm_reg_file_in <= 0;
		cpsr_data_issue_pipes_frm_reg_file_in <= 0;

		// Wait 100 ns for global reset to finish
		#105;
		reset_in <= 1'b0;
		#10
		new_entry_word1_in <= 21'b0000_0000_0001_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b0001_0001_0010_1_0_1_1_1_1_0_0_0;
		reorder_buffer_update_in <= 1;
		
		#10
		new_entry_word1_in <= 21'b0010_0001_0011_0_0_1_0_0_1_0_0_0;
		new_entry_word2_in <= 21'b0011_0001_0100_1_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 1;
		
		#10
		new_entry_word1_in <= 21'b0100_0110_0101_0_0_1_0_0_1_0_0_0;
		new_entry_word2_in <= 21'b0101_0001_0110_1_0_1_1_1_1_0_0_0;
		reorder_buffer_update_in <= 1;
		
		#10
		new_entry_word1_in <= 21'b0110_0110_0111_0_0_0_0_1_1_0_1_0;
		new_entry_word2_in <= 21'b0111_0111_1000_0_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 1;
		
		#10
		new_entry_word1_in <= 3;
		new_entry_word2_in <= 4;
		reorder_buffer_update_in <= 0;
		rd_data_alu_pipe1_in <= 1;
	   rd_data_alu_pipe2_in <= 2;
	   rd_data_load_store_pipe3_in <= 3;
	   rd_data_branch_pipe4_in <= 4;
		rn_data_alu_pipe1_in <= 1;
	   rn_data_alu_pipe2_in <= 2;
	   rn_data_load_store_pipe3_in <= 3;
	   rn_data_branch_pipe4_in <= 4;
		cpsr_data_alu_pipe1_in <= 1;
	   cpsr_data_alu_pipe2_in <= 2;
	   cpsr_data_load_store_pipe3_in <= 3;
	   cpsr_data_branch_pipe4_in <= 4;
		tag_bits_pipes_combined_in <= 16'b0000_0100_0010_0011;
		rd_addr_pipes_combined_in <= 16'b0000_0110_0001_0001;
		rn_addr_pipes_combined_in <= 16'b0001_0101_0011_0100;
	   instr_complete_frm_pipes_in <= 4'b1111;
		speculative_result_in <= 4'b1111;
		
		#10
		new_entry_word1_in <= 21'b1000_1000_1001_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1001_1001_1010_0_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 1;
		rd_data_alu_pipe1_in <= 5;
	   rd_data_alu_pipe2_in <= 6;
	   rd_data_load_store_pipe3_in <= 7;
	   rd_data_branch_pipe4_in <= 8;
		rn_data_alu_pipe1_in <= 5;
	   rn_data_alu_pipe2_in <= 6;
	   rn_data_load_store_pipe3_in <= 7;
	   rn_data_branch_pipe4_in <= 8;
		cpsr_data_alu_pipe1_in <= 5;
	   cpsr_data_alu_pipe2_in <= 6;
	   cpsr_data_load_store_pipe3_in <= 7;
	   cpsr_data_branch_pipe4_in <= 8;
		tag_bits_pipes_combined_in <= 16'b0001_0101_1000_0111;
		rd_addr_pipes_combined_in <= 16'b0001_0001_0001_0111;
		rn_addr_pipes_combined_in <= 16'b0010_0110_0001_1000;
	   instr_complete_frm_pipes_in <= 4'b1100;
		speculative_result_in <= 4'b1011;
		tag_bits_for_rd_to_issue_in <= 0;
		rd_addr_to_issue_in <= 4'b0001;
		tag_bits_for_rn_to_issue_in <= 12'b0001_0010_0011;
		rn_addr_to_issue_in <= 12'b0010_0011_0100;
		tag_bits_for_rm_to_issue_in <= 16'b0001_0010_0011_0100;
		rm_addr_to_issue_in <= 16'b0010_0010_0100_0110;
		
		#10
		new_entry_word1_in <= 7;
		new_entry_word2_in <= 8;
		reorder_buffer_update_in <= 0;
		rd_data_alu_pipe1_in <= 0;
	   rd_data_alu_pipe2_in <= 0;
	   rd_data_load_store_pipe3_in <= 0;
	   rd_data_branch_pipe4_in <= 0;
		rn_data_alu_pipe1_in <= 0;
	   rn_data_alu_pipe2_in <= 0;
	   rn_data_load_store_pipe3_in <= 0;
	   rn_data_branch_pipe4_in <= 0;
		cpsr_data_alu_pipe1_in <= 0;
	   cpsr_data_alu_pipe2_in <= 0;
	   cpsr_data_load_store_pipe3_in <= 0;
	   cpsr_data_branch_pipe4_in <= 0;
		tag_bits_pipes_combined_in <= 0;
	   instr_complete_frm_pipes_in <= 0;
		tag_bits_for_rd_to_issue_in <= 0;
		rd_addr_to_issue_in <= 0;
		tag_bits_for_rn_to_issue_in <= 0;
		rn_addr_to_issue_in <= 0;
		tag_bits_for_rm_to_issue_in <= 0;
		rm_addr_to_issue_in <= 0;
		speculative_result_in <= 0;
		rd_addr_pipes_combined_in <= 0;
		rn_addr_pipes_combined_in <= 0;
		
		#10
		new_entry_word1_in <= 21'b1010_1010_1011_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1011_1011_1100_0_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 1;
				
		#10
		new_entry_word1_in <= 21'b1100_1100_1101_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1101_1101_1110_0_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 1;
		rd_data_load_store_pipe3_in <= 2;
	   tag_bits_pipes_combined_in <= 16'b0000_0100_0110_0101;
	   rd_addr_pipes_combined_in <= 16'b0000_0110_0001_0011;
		ldm_stall_in <= 1;
		reg_update_ldm_stm_in <= 1;
		
		#10
		new_entry_word1_in <= 21'b1100_1100_1101_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1101_1101_1110_0_0_1_1_0_1_0_0_0;
		reorder_buffer_update_in <= 0;
		rd_data_load_store_pipe3_in <= 3;
	   tag_bits_pipes_combined_in <= 16'b0000_0100_0110_0101;
	   rd_addr_pipes_combined_in <= 16'b0000_0110_0010_0011;
		ldm_stall_in <= 1;
		reg_update_ldm_stm_in <= 0;
		
		#10
		new_entry_word1_in <= 21'b1100_1100_1101_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1101_1101_1110_0_0_1_1_0_1_0_0_0;
		rd_data_load_store_pipe3_in <= 4;
	   tag_bits_pipes_combined_in <= 16'b0000_0100_0110_0101;
	   rd_addr_pipes_combined_in <= 16'b0000_0110_0011_0011;
		ldm_stall_in <= 1;
		reg_update_ldm_stm_in <= 0;
		
		#10
		new_entry_word1_in <= 21'b1100_1100_1101_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1101_1101_1110_0_0_1_1_0_1_0_0_0;
		rd_data_load_store_pipe3_in <= 5;
	   tag_bits_pipes_combined_in <= 16'b0000_0100_0110_0101;
	   rd_addr_pipes_combined_in <= 16'b0000_0110_0100_0011;
		ldm_stall_in <= 1;
		instr_complete_frm_pipes_in <= 4'b0010;
		reg_update_ldm_stm_in <= 0;
		
		#10
		new_entry_word1_in <= 21'b1100_1100_1101_0_0_1_0_1_1_0_0_0;
		new_entry_word2_in <= 21'b1101_1101_1110_0_0_1_1_0_1_0_0_0;
		rd_data_load_store_pipe3_in <= 4;
	   tag_bits_pipes_combined_in <= 16'b0000_0100_0110_0101;
	   rd_addr_pipes_combined_in <= 16'b0000_0110_0011_0011;
		ldm_stall_in <= 0;
		reg_update_ldm_stm_in <= 0;
		
		#10
		tag_bits_for_rs_to_issue_in <= 12'b0110_0010_0011;
		rs_addr_to_issue_in <= 12'b0001_0011_0100;
		tag_bits_for_rm_to_issue_in <= 16'b0001_0010_0110_0100;
		rm_addr_to_issue_in <= 16'b0001_0011_0010_0110;
		
		#10
		tag_bits_for_rs_to_issue_in <= 0;
		rs_addr_to_issue_in <= 0;
		tag_bits_for_rm_to_issue_in <= 0;
		rs_addr_to_issue_in <= 0;
        
		// Add stimulus here

	end
   
	always #5 clk_in = ~clk_in;
   
endmodule

