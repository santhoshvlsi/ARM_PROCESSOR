`include "timescale.v"
`include "alu_pipe_barrel_shifter_define.v"

module alu_pipe(	 
					input clk_in,
					input reset_in,
					input [`ALU_PIPE_CONTROL_WORD_SIZE-1:0] alu_pipe_control_word_in,
					output [31:0] cpsr_out,
					output [31:0] rd_data_out,
					output instr_exec_confirmed_out,
					output instr_exec_complete_out,
					output [3:0] instr_tag_out,
					output [3:0] rd_addr_out
    );

wire reg_imm_sel,alu_pipe_start;
wire [`REG_DATA_SIZE-1:0] alu_operandB_reg,alu_operandB,alu_operandB_imm;
wire [`BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CONTROL_WORD_SIZE-1:0] barrel_shifter_control_word;
wire [`REG_DATA_SIZE-1:0] shifted_operandB_BS_stage;
wire instr_exec_confirmed_BS_stage;
wire carry_frm_barrel_shifter_BS_stage;
wire [`REG_DATA_SIZE-1:0] alu_operandA,alu_operandA_BS_stage;
wire pipe_BS_stage;
wire [`TAG_BITS_SIZE-1:0] instr_tag,instr_tag_BS_stage;
wire [`REG_ADDR_SIZE-1:0] rd_addr,rd_addr_BS_stage;
wire [`ALU_CONTROL_SIZE-1:0] alu_control,alu_control_BS_stage;
wire carry_BS_stage;
wire ctrl_clz_BS_stage;
wire carry_barrel_shifter_update_BS_stage;
wire [`ALU_STAGE_CONTROL_WORD_SIZE-1:0] alu_clz_control_word;
wire [`FLAG_REGISTER_SIZE-1:0] flag_register;
wire [`REST_OF_CPSR_BITS_SIZE-1:0] rest_of_cpsr,rest_of_cpsr_BS_stage,rest_of_cpsr_ALU_CLZ_stage;

/******BARREL_SHIFTER_PLUS_CONDITIONAL_STAGE_STARTS******/
	/******ALU_OPERAND_B******/
	assign reg_imm_sel = alu_pipe_control_word_in[`ALU_PIPE_REG_IMM_SEL];
	assign alu_operandB_reg = alu_pipe_control_word_in[`ALU_PIPE_OPERANDB_START:`ALU_PIPE_OPERANDB_END];
	assign alu_operandB_imm = {{24{1'b0}},
	alu_pipe_control_word_in[`ALU_PIPE_IMM_FRM_INSTR_START:`ALU_PIPE_IMM_FRM_INSTR_END]};
	assign alu_operandB = reg_imm_sel ? alu_operandB_reg : alu_operandB_imm;
	/******ALU_OPERAND_B******/

	/******ALU_OPERAND_A******/
	assign alu_operandA = alu_pipe_control_word_in[`ALU_PIPE_OPERANDA_START:`ALU_PIPE_OPERANDA_END];
	/******ALU_OPERAND_A******/

	/******INSTR_TAG******/
	assign instr_tag = alu_pipe_control_word_in[`ALU_PIPE_INSTR_TAG_START:`ALU_PIPE_INSTR_TAG_END];
	/******INSTR_TAG******/

	/******RD_ADDR******/
	assign rd_addr = alu_pipe_control_word_in[`ALU_PIPE_RD_ADDR_START:`ALU_PIPE_RD_ADDR_END];
	/******RD_ADDR******/

	/******ALU_CONTROL******/
	assign alu_control = 
	alu_pipe_control_word_in[`ALU_PIPE_ALU_CONTROL_START:`ALU_PIPE_ALU_CONTROL_END];
	/******ALU_CONTROL******/
	
	/******REST_OF_CPSR******/
	assign rest_of_cpsr = alu_pipe_control_word_in[`ALU_PIPE_REST_OF_CPSR_START:`ALU_PIPE_CPSR_END];
	/******REST_OF_CPSR******/
	
	/******ALU_PIPE_START******/
	assign alu_pipe_start = alu_pipe_control_word_in[`ALU_PIPE_START];
	/******ALU_PIPE_START******/

	/******BARREL_SHIFTER_CONTROL_WORD******/
	assign barrel_shifter_control_word = 
	{alu_pipe_control_word_in[`ALU_PIPE_CPSR_FLAG_START:`ALU_PIPE_CPSR_FLAG_END], //Flag bits
	alu_operandB,	//Operand to be shifted
	alu_pipe_control_word_in[`ALU_PIPE_RS_SHIFT_VALUE_START:`ALU_PIPE_RS_SHIFT_VALUE_END], //Shift value from register in rs field
	alu_pipe_control_word_in[`ALU_PIPE_SHIFT_VALUE_START:`ALU_PIPE_SHIFT_VALUE_END], //Shift value decoded from instruction
	alu_pipe_control_word_in[`ALU_PIPE_SHIFT_OPCODE_START:`ALU_PIPE_SHIFT_OPCODE_END], //Shift opcode
	alu_pipe_control_word_in[`ALU_PIPE_RS_TO_SHIFT], //Whether to use value from rs
	alu_pipe_control_word_in[`ALU_PIPE_COND_BITS_START:`ALU_PIPE_COND_BITS_END]}; //Conditional bits
	/******BARREL_SHIFTER_CONTROL_WORD******/

	/******BARREL_SHIFTER_PLUS_CONDITIONAL_CHECK_STAGE******/
	barrel_shifter_stage barrel_shifter_plus_conditional_check (
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .barrel_shifter_for_alu_control_word_in(barrel_shifter_control_word), 
		 .shifted_operandB_out(shifted_operandB_BS_stage), 
		 .instr_exec_out(instr_exec_confirmed_BS_stage), 
		 .carry_frm_barrel_shifter_out(carry_frm_barrel_shifter_BS_stage)
		 );
	/******BARREL_SHIFTER_PLUS_CONDITIONAL_CHECK_STAGE******/

	/******ALU_OPERAND_A******/
	register_with_reset #`REG_DATA_SIZE reg_alu_operandA_BS_stage (
			 .data_in(alu_operandA), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(alu_operandA_BS_stage)
			 );
	/******ALU_OPERAND_A******/

	/******PIPE_START******/
	register_with_reset #1 reg_pipe_BS_complete (
			 .data_in(alu_pipe_start), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(1'b1), 
			 .data_out(pipe_BS_stage)
			 );
	/******PIPE_START******/

	/******INSTR_TAG******/
	register_with_reset #`TAG_BITS_SIZE reg_instr_tag_BS_stage (
			 .data_in(instr_tag), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(instr_tag_BS_stage)
			 );
	/******INSTR_TAG******/

	/******RD_ADDR******/
	register_with_reset #`REG_ADDR_SIZE reg_rd_addr_BS_stage (
			 .data_in(rd_addr), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(rd_addr_BS_stage)
			 );
	/******RD_ADDR******/

	/******ALU_CONTROL******/
	register_with_reset #`ALU_CONTROL_SIZE reg_alu_control_BS_stage (
			 .data_in(alu_control), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(alu_control_BS_stage)
			 );
	/******ALU_CONTROL******/

	/******CARRY******/
	register_with_reset #1 reg_carry_BS_stage (
			 .data_in(alu_pipe_control_word_in[`ALU_PIPE_CARRY]), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(carry_BS_stage)
			 );
	/******CARRY******/

	/******CTRL_CLZ******/
	register_with_reset #1 reg_ctrl_clz_BS_stage (
			 .data_in(alu_pipe_control_word_in[`ALU_PIPE_CTRL_CLZ]), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(ctrl_clz_BS_stage)
			 );
	/******CTRL_CLZ******/

	/******CARRY_BARREL_SHIFTER_UPDATE******/
	register_with_reset #1 reg_carry_barrel_shifter_update_S1 (
			 .data_in(alu_pipe_control_word_in[`ALU_PIPE_CARRY_BARREL_SHIFTER_UPDATE]), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(carry_barrel_shifter_update_BS_stage)
			 );
	/******CARRY_BARREL_SHIFTER_UPDATE******/
	
	/******REST_OF_CPSR******/
	register_with_reset #`REST_OF_CPSR_BITS_SIZE reg_rest_of_cpsr_BS_stage (
			 .data_in(rest_of_cpsr), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(alu_pipe_start), 
			 .data_out(rest_of_cpsr_BS_stage)
			 );
	/******REST_OF_CPSR******/			 
/******BARREL_SHIFTER_PLUS_CONDITIONAL_STAGE_ENDS******/

/******ALU_STAGE_STARTS******/
	/******ALU_CLZ_CONTROL_WORD******/
	assign alu_clz_control_word = {carry_BS_stage,
	alu_operandA_BS_stage,
	shifted_operandB_BS_stage,
	alu_control_BS_stage,
	ctrl_clz_BS_stage,
	carry_barrel_shifter_update_BS_stage,
	carry_frm_barrel_shifter_BS_stage};
	/******ALU_CLZ_CONTROL_WORD******/
	
	
	/******INSTR_EXEC_CONFIRMED******/
	register_with_reset #1 reg_instr_exec_confirmed_out (
		 .data_in(~instr_exec_confirmed_BS_stage), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(pipe_BS_stage), 
		 .data_out(instr_exec_confirmed_out)
		 );
	/******INSTR_EXEC_CONFIRMED******/
	
	/******INSTR_EXEC_COMPLETE******/
	register_with_reset #1 reg_instr_exec_complete_out (
		 .data_in(pipe_BS_stage), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(instr_exec_complete_out)
		 );
	/******INSTR_EXEC_COMPLETE******/
	
	/******INSTR_TAG******/
	register_with_reset #`TAG_BITS_SIZE reg_instr_tag_out (
			 .data_in(instr_tag_BS_stage), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(pipe_BS_stage), 
			 .data_out(instr_tag_out)
			 );
	/******INSTR_TAG******/
	
	/******RD_ADDR******/
	register_with_reset #`REG_ADDR_SIZE reg_rd_addr_out (
			 .data_in(rd_addr_BS_stage), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(pipe_BS_stage), 
			 .data_out(rd_addr_out)
			 );
	/******RD_ADDR******/
	
	/******REST_OF_CPSR******/
	register_with_reset #`REST_OF_CPSR_BITS_SIZE reg_rest_of_cpsr_ALU_CLZ_stage (
			 .data_in(rest_of_cpsr_BS_stage), 
			 .clk_in(clk_in), 
			 .reset_in(reset_in), 
			 .en_in(pipe_BS_stage), 
			 .data_out(rest_of_cpsr_ALU_CLZ_stage)
			 );
	/******REST_OF_CPSR******/	
	
	/******ALU******/
	alu_stage alu_plus_clz (
    .clk_in(clk_in), 
    .reset_in(reset_in), 
    .alu_stage_control_word_in(alu_clz_control_word), 
    .alu_result_out(rd_data_out), 
    .flag_register_out(flag_register)
    );
	 /******ALU******/
	 
	 assign cpsr_out = {flag_register,rest_of_cpsr_ALU_CLZ_stage};

endmodule
