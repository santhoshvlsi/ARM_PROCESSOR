`include "timescale.v" 

module alu(
    input [31:0] s_in,
    input [31:0] t_in,
    input [3:0] alucontrol_in,
    input carry_in,
	 input ctrl_clz_in,
    output [31:0] result_out,
	 output carry_flag_out,
	 output negative_flag_out,
	 output overflow_flag_out,
	 output zero_flag_out
    );

wire carry;
wire carry_out;
wire [7:0] control_signals;
wire [31:0] adder_result;
wire [31:0] or_result;
wire [31:0] and_result;
wire [31:0] xor_result;
wire [31:0] not_result;
wire [31:0] a;
wire [31:0] b;
wire [31:0] t_AND_BIC;
wire [31:0] clz_result;
wire [31:0] result_out_buff;


alu_decoder alu_control_decoder (
    .alucontrol_in(alucontrol_in), 
    .control_signals_out(control_signals)
    );



mux4 #1 carry_in_sel (
    .y_out(carry), 
    .i0_in(1'b0), 
    .i1_in(1'b1), 
    .i2_in(carry_in), 
    .i3_in(~ carry_in), 
    .sel_in(control_signals[7:6])
    );

mux2 #32 a_in_sel_arithmetic_mux (
    .y_out(a), 
    .i0_in(s_in), 
    .i1_in(t_in), 
    .sel_in(control_signals[5])
    );

mux4 #32 b_in_sel_arithmetic_mux (
    .y_out(b), 
    .i0_in(t_in), 
    .i1_in(not_result), 
    .i2_in(~ s_in), 
    .i3_in(32'b0), 
    .sel_in(control_signals[5:4])
    );


adder_alu arithmetic (
    .a_in(a), 
    .b_in(b), 
	 .carry_in(carry),
    .sum_out(adder_result), 
    .carry_out(carry_out)
    );

mux2 #1 carry_out_sel_mux (
    .y_out(carry_flag_out), 
    .i0_in(carry_out), 
    .i1_in(carry_in), 
    .sel_in(control_signals[0] | control_signals[1] | control_signals[2]   )
    );

assign or_result = s_in | t_in;
assign xor_result = s_in ^ t_in;
assign not_result = ~ t_in;

mux2 #32 AND_BIC_sel_mux (
    .y_out(t_AND_BIC), 
    .i0_in(t_in), 		// for AND instruction
    .i1_in(not_result), //for BIC instruction
    .sel_in(control_signals[3])
    );

assign and_result = s_in & t_AND_BIC;

mux8 #32 output_sel_mux (
    .y_out(result_out_buff), 
    .i0_in(adder_result), 
    .i1_in(or_result), 
    .i2_in(and_result), 
    .i3_in(not_result), 
    .i4_in(xor_result), 
    .i5_in(t_in), //for mov instruction
    .i6_in(32'b0), 
    .i7_in(32'b0), 
    .sel_in(control_signals[2:0])
    );
	 
	 
assign negative_flag_out = result_out_buff[31];
assign zero_flag_out = ~(|(result_out_buff));
assign overflow_flag_out = (&(result_out_buff) & carry_flag_out); 


clz_calc clz_calculator (.data_in(t_in),
								 .data_out(clz_result));

mux2 #32 CLZ_ALU_sel_mux (
    .y_out(result_out), 
    .i0_in(result_out_buff), 	
    .i1_in(clz_result),
    .sel_in(ctrl_clz_in)
    );


endmodule
