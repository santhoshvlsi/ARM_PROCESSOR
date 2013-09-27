`include "timescale.v"
module barrel_shifter(
    input [31:0] data_in,
    input [4:0] shift_amount,
    input [3:0] opcode,
	 input cf_in,
	 input instr_exec_in,
	 output cf_out,
    output [31:0] data_out
    ); 

/*LSL = 0100
LSR = 0000
ASR = 0001
RRX = 1010
ROR = 0010
*/


wire [31:0] data_buff;
wire [31:0] data_out_buff;
wire [31:0] stage_1;
wire [31:0] stage_2;
wire [31:0] stage_3;
wire [31:0] stage_4;
wire [31:0] stage_5;
wire [15:0] stage_partial_1;
wire [15:0] data_buff_cf;
wire [7:0] stage_partial_2;
wire [7:0] stage_1_cf;
wire [3:0] stage_partial_3;
wire [3:0] stage_2_cf;
wire [1:0] stage_partial_4;
wire [1:0] stage_3_cf;
wire  stage_partial_5;
wire stage_4_cf;
wire arith_buff;
wire cf_buff;
wire rrx_cf_bit_stage_2;
wire rrx_cf_bit_stage_3;
wire rrx_cf_bit_stage_4;
wire rrx_cf_bit_stage_5;

assign cf_buff = (shift_amount[4] | shift_amount[3] | shift_amount[2] | shift_amount[1] | shift_amount[0]) & instr_exec_in;
assign cf_out = cf_buff ? stage_4[0] : cf_in;//(stage_4[0] & (shift_amount[4] | shift_amount[3] | shift_amount[2] | shift_amount[1] | shift_amount[0]));

assign arith_buff = opcode[0] ? data_buff[31] : 1'b0;
//////////////////////////////////////////////////////////////////////////////////////
//assign data_out_buff[31] = opcode[0] ? data_buff[31] : stage_5[31];
genvar a;
generate
for(a=0;a<=31;a=a+1)
begin : inst13
	assign data_out_buff[a] = stage_5[a];
end
endgenerate
//////////////////////////////////////////////////////////////////////////////////////
genvar b;
generate
for(b=0;b<=31;b=b+1)
begin : inst1
	assign data_buff[b] = opcode[2] ? data_in[31-b] : data_in[b];
	assign data_out[b] = opcode[2] ? data_out_buff[31-b] : data_out_buff[b];
end
endgenerate	
//////////////////////////////////////////////////////////////////////////////////////
//stage_1 : STARTS
assign data_buff_cf[0] = opcode[3] ? cf_in : data_buff[0];
genvar m;
generate
for (m=1;m<=15;m=m+1)
begin : inst14
	assign data_buff_cf[m] = opcode[3] ? data_buff[m-1] : data_buff[m];
end
endgenerate
genvar c;
generate
for(c=0;c<=15;c=c+1)
begin : inst3
	assign stage_partial_1[c] = opcode[1] ? data_buff_cf[c] : arith_buff;
	assign stage_1[c] = shift_amount[4] ? data_buff[c+16] : data_buff[c];
	assign stage_1[c+16] = shift_amount[4] ? stage_partial_1[c] : data_buff[c+16];
end
endgenerate//stage_1 : ENDS
//////////////////////////////////////////////////////////////////////////////////////
//stage_2 : STARTS

assign rrx_cf_bit_stage_2 = shift_amount[4] ? data_buff[15] : cf_in;
assign stage_1_cf[0] = opcode[3] ?  rrx_cf_bit_stage_2 : stage_1[0];
genvar n;
generate
for (n=1;n<=7;n=n+1)
begin : inst15
	assign stage_1_cf[n] = opcode[3] ? stage_1[n-1] : stage_1[n];
end
endgenerate
genvar e;
generate
for(e=0;e<=7;e=e+1)
begin : inst5
	assign stage_partial_2[e] = opcode[1] ? stage_1_cf[e] : arith_buff; 
	assign stage_2[e+24] = shift_amount[3] ? stage_partial_2[e] : stage_1[e+24];
end
endgenerate
genvar f;
generate
for(f=0;f<=23;f=f+1)
begin : inst6
	assign stage_2[f] = shift_amount[3] ? stage_1[f+8] : stage_1[f];
end
endgenerate//stage_2 : ENDS
//////////////////////////////////////////////////////////////////////////////////////
//stage_3 : STARTS
//assign stage_2_cf[0] = opcode[3] ? (shift_amount[3] ? stage_2[7] : cf_in ) : stage_2[0];
assign rrx_cf_bit_stage_3 = shift_amount[3] ? stage_1[7] : rrx_cf_bit_stage_2;
assign stage_2_cf[0] = opcode[3] ? rrx_cf_bit_stage_3 : stage_2[0];
genvar o;
generate
for (o=1;o<=3;o=o+1)
begin : inst16
	assign stage_2_cf[o] = opcode[3] ? stage_2[o-1] : stage_2[o];
end
endgenerate

genvar h;
generate
for(h=0;h<=3;h=h+1)
begin : inst8
	assign stage_partial_3[h] = opcode[1] ? stage_2_cf[h] : arith_buff;
	assign stage_3[h+28] = shift_amount[2] ? stage_partial_3[h] : stage_2[h+28];
end
endgenerate
genvar i;
generate
for(i=0;i<=27;i=i+1)
begin : inst9
	assign stage_3[i] = shift_amount[2] ? stage_2[i+4] : stage_2[i];
end
endgenerate//stage_3 : ENDS
//////////////////////////////////////////////////////////////////////////////////////
//stage_4 : STARTS
//assign stage_3_cf[0] = opcode[3] ? (shift_amount[2] ? stage_3[3] : cf_in ): stage_3[0];
assign rrx_cf_bit_stage_4 = shift_amount[2] ? stage_2[3] : rrx_cf_bit_stage_3;
assign stage_3_cf[0] = opcode[3] ? rrx_cf_bit_stage_4 : stage_3[0];
assign stage_3_cf[1] = opcode[3] ? stage_3[0] : stage_3[1];
genvar j;
generate
for(j=0;j<=1;j=j+1)
begin : inst10
	assign stage_partial_4[j] = opcode[1] ? stage_3_cf[j] : arith_buff;
	assign stage_4[j+30] = shift_amount[1] ? stage_partial_4[j] : stage_3[j+30];
end
endgenerate
genvar k;
generate
for(k=0;k<=29;k=k+1)
begin : inst11
	assign stage_4[k] = shift_amount[1] ?  stage_3[k+2] : stage_3[k];
end
endgenerate//stage_4 : ENDS
//////////////////////////////////////////////////////////////////////////////////////
//stage_5 : STARTS
//assign stage_4_cf[0] = opcode[3]?  (shift_amount[1] ? stage_4[1] : cf_in ) : stage_4[0];
assign rrx_cf_bit_stage_5 = shift_amount[1] ? stage_3[1] : rrx_cf_bit_stage_4;
assign stage_4_cf = opcode[3]?  rrx_cf_bit_stage_5 : stage_4[0];
assign stage_partial_5 = opcode[1] ? stage_4_cf : arith_buff;
assign stage_5[31] = shift_amount[0] ? stage_partial_5 : stage_4[31];

genvar l;
generate
for(l=0;l<=30;l=l+1)
begin : inst12
	assign stage_5[l] = shift_amount[0] ? stage_4[l+1] : stage_4[l];
end
endgenerate//stage_5 : ENDS
//////////////////////////////////////////////////////////////////////////////////////
endmodule
