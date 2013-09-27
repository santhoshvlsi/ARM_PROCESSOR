`include "timescale.v"
`include "alu_pipe_barrel_shifter_define.v"
module barrel_shifter_stage(
			input clk_in,
			input reset_in,
			input [`BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CONTROL_WORD_SIZE-1:0] 
			barrel_shifter_for_alu_control_word_in,
			output [31:0] shifted_operandB_out,
			output instr_exec_out,
			output carry_frm_barrel_shifter_out
    );

wire [4:0] shift_amount,shift_from_Rs,shift_value;
wire [31:0] alu_operandB;
wire instr_exec;
wire carry;
wire use_rs_to_shift;

assign use_rs_to_shift = 
barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_USE_RS_TO_SHIFT];
assign shift_from_Rs = 
barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_FROM_RS_START:
`BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_FROM_RS_END];
assign shift_value = 
barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_VALUE_START:
`BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_VALUE_END];

assign shift_amount = use_rs_to_shift ? shift_from_Rs : shift_value;

cond_instr_sel conditional_instr_sel (
    .cond_in(barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_COND_BITS_START:
	 `BARREL_SHIFTER_STAGE_FOR_ALU_COND_BITS_END]), 
    .flag_register_in(
	 barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_FLAG_START:
	 `BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_FLAG_END]), 
    .instr_exec_out(instr_exec)
    );

barrel_shifter barr_shifter (
    .data_in(barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_OPERAND_B_START:
	 `BARREL_SHIFTER_STAGE_FOR_ALU_OPERAND_B_END]), 
    .shift_amount(shift_amount), 
    .opcode(barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_OPCODE_START:
	 `BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_OPCODE_END]), 
    .cf_in(barrel_shifter_for_alu_control_word_in[`BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CARRY]), 
    .instr_exec_in(instr_exec), 
    .cf_out(carry), 
    .data_out(alu_operandB)
    );

register_with_reset #32 barrel_shifter_out (
		 .data_in(alu_operandB), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(shifted_operandB_out)
		 );

register_with_reset #1 reg_instr_exec (
		 .data_in(instr_exec), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(instr_exec_out)
		 );

register_with_reset #1 reg_carry (
		 .data_in(carry), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(carry_frm_barrel_shifter_out)
		 );

endmodule
