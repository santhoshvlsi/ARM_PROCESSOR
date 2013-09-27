`include "timescale.v"
`include "alu_pipe_barrel_shifter_define.v"


module alu_stage(
		input clk_in,
		input reset_in,
		input [`ALU_STAGE_CONTROL_WORD_SIZE-1:0] alu_stage_control_word_in,
		output [31:0] alu_result_out,
		output [3:0] flag_register_out 
    );
 
wire [31:0] result; 
wire carry;
wire carry_final;
wire negative;
wire overflow;
wire zero;

alu arithmetic_logic_unit (
    .s_in(alu_stage_control_word_in[`ALU_STAGE_OPERAND_A_START:`ALU_STAGE_OPERAND_A_END]), 
    .t_in(alu_stage_control_word_in[`ALU_STAGE_OPERAND_B_START:`ALU_STAGE_OPERAND_B_END]), 
    .alucontrol_in(alu_stage_control_word_in[`ALU_STAGE_CONTROL_START:`ALU_STAGE_CONTROL_END]), 
    .carry_in(alu_stage_control_word_in[`ALU_STAGE_CARRY]), 
    .ctrl_clz_in(alu_stage_control_word_in[`ALU_STAGE_CTRL_CLZ]), 
    .result_out(result), 
    .carry_flag_out(carry), 
    .negative_flag_out(negative), 
    .overflow_flag_out(overflow), 
    .zero_flag_out(zero)
    );
	 
register_with_reset #32 reg_alu_result (
		 .data_in(result), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(alu_result_out)
		 );

assign carry_final = alu_stage_control_word_in[`ALU_STAGE_CARRY_BARREL_SHIFTER_UPDATE] ? 
alu_stage_control_word_in[`ALU_CARRY_FRM_BARREL_SHIFTER] : carry;

register_with_reset #4 reg_flag_register (
		 .data_in({negative,zero,carry_final,overflow}), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(flag_register_out)
		 );


endmodule
