`include "timescale.v"
`include "alu_pipe_barrel_shifter_define.v"

module tb_alu_pipe;

	// Inputs
	reg clk_in;
	reg reset_in;
	reg [31:0] cpsr;
	reg [31:0] operandA;
	reg [31:0] operandB;
	reg [7:0] immediate;
	reg reg_imm_sel;
	reg [4:0] rs_shift_value;
	reg [4:0] shift_value;
	reg [3:0] shift_opcode;
	reg rs_to_shift;
	reg [3:0] alu_control;
	reg ctrl_clz;
	reg [3:0] cond_bits;
	reg carry_barrel_shifter_update;
	reg [3:0] instr_tag;
	reg [3:0] rd_addr;
	reg pipe_start;

	// Outputs
	wire [31:0] cpsr_out;
	wire [31:0] rd_data_out; 
	wire instr_exec_confirmed_out;
	wire instr_exec_complete_out;
	wire [3:0] instr_tag_out;
	wire [3:0] rd_addr_out;

	// Instantiate the Unit Under Test (UUT)
	alu_pipe uut (
		.clk_in(clk_in), 
		.reset_in(reset_in), 
		.alu_pipe_control_word_in({cpsr,operandA,operandB,immediate,reg_imm_sel,rs_shift_value,
		shift_value,shift_opcode,rs_to_shift,alu_control,ctrl_clz,cond_bits,carry_barrel_shifter_update,
		instr_tag,rd_addr,pipe_start}), 
		.cpsr_out(cpsr_out), 
		.rd_data_out(rd_data_out), 
		.instr_exec_confirmed_out(instr_exec_confirmed_out), 
		.instr_exec_complete_out(instr_exec_complete_out), 
		.instr_tag_out(instr_tag_out), 
		.rd_addr_out(rd_addr_out)
	);
	
	
	initial begin
		// Initialize Inputs
		clk_in <= 0;
		reset_in <= 1;
		cpsr <= 0;
		operandA <= 0;
		operandB <= 0;
		immediate <= 0;
		reg_imm_sel <= 0;
		rs_shift_value <= 0;
		shift_value <= 0;
		shift_opcode <= 0;
		rs_to_shift <= 0;
		alu_control <= 0;
		ctrl_clz <= 0;
		cond_bits <= 0;
		carry_barrel_shifter_update <= 0;
		instr_tag <= 0;
		rd_addr <= 0;
		pipe_start <= 0;

		// Wait 100 ns for global reset to finish
		#105;
		reset_in <= 1'b0;
		#10
		cpsr <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
		operandA <= 5;
		operandB <= 10;
		immediate <= 20;
		reg_imm_sel <= 0;
		rs_shift_value <= 6;
		shift_value <= 8;
		shift_opcode <= 4;
		rs_to_shift <= 0;
		alu_control <= 4;
		ctrl_clz <= 0;
		cond_bits <= 14;
		carry_barrel_shifter_update <= 0;
		instr_tag <= 0;
		rd_addr <= 0;
		pipe_start <= 1;
		#10
		cpsr <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
		operandA <= 15;
		operandB <= 20;
		immediate <= 20;
		reg_imm_sel <= 1;
		rs_shift_value <= 6;
		shift_value <= 8;
		shift_opcode <= 4;
		rs_to_shift <= 0;
		alu_control <= 4;
		ctrl_clz <= 0;
		cond_bits <= 0;
		carry_barrel_shifter_update <= 0;
		instr_tag <= 0;
		rd_addr <= 0;
		pipe_start <= 1;
        
		// Add stimulus here

	end
	
	always #5 clk_in = ~clk_in;
      
endmodule

