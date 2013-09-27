`include "timescale.v"
module adder_alu(
    input [31:0] a_in,
    input [31:0] b_in,
	 input carry_in,
    output [31:0] sum_out,
	 output carry_out
    );

wire [32:0] sum_buffer;

assign sum_buffer = a_in + b_in + carry_in;
assign sum_out = sum_buffer[31:0];
assign carry_out = sum_buffer[32];

endmodule
