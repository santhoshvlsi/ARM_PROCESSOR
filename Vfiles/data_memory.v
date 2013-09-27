`include "load_store_memory_stage_define.v"  
`include "timescale.v"
module data_memory(
						output [31:0] rd_out,
						input [31:0] addr_in,
						input [3:0] we_in,
						input [31:0] wd_in,
						input clk_in,
						input swp_ctrl_in,
						//input en_in,
						input reset_in,
						input [2:0] ctrl_load_mux_in,
						input [2:0] ctrl_str_mux_in);

wire [31:0] rd_buff;
wire [31:0] wd_buff;
wire [3:0] w_en;

assign w_en = swp_ctrl_in ? 4'b1111 : we_in;

memory_instr8  mem8(.rd_out(rd_buff[31:24]),
					 .addr_in(addr_in),
					 .we_in(w_en[3]),
					 .wd_in(wd_buff[31:24]),
					 .reset_in(reset_in),
					 //.en_in(~en_in),
					 .clk_in(clk_in));
memory_instr7  mem7(.rd_out(rd_buff[23:16]),
					 .addr_in(addr_in),
					 .we_in(w_en[2]),
					 .wd_in(wd_buff[23:16]),
					 .reset_in(reset_in),
					 //.en_in(~en_in),
					 .clk_in(clk_in));
memory_instr6  mem6(.rd_out(rd_buff[15: 8]),
					 .addr_in(addr_in),
					 .we_in(w_en[1]),
					 .wd_in(wd_buff[15:8]),
					 .reset_in(reset_in),
					 //.en_in(~en_in),
					 .clk_in(clk_in));
memory_instr5  mem5(.rd_out(rd_buff[7: 0]),
					 .addr_in(addr_in),
					 .we_in(w_en[0]),
					 .wd_in(wd_buff[7:0]),
					 .reset_in(reset_in),
					 //.en_in(~en_in),
					 .clk_in(clk_in));
					 
/*mux8_32 mux_load (.y_out(rd_out), 
							 .i0_in(rd_buff), 
							 .i1_in({{16{1'b0}},rd_buff[15:0]}), 
							 .i2_in({{16{rd_buff[15]}},rd_buff[15:0]}), 
						    .i3_in({{24{1'b0}},rd_buff[7:0]}),
							 .i4_in({{24{rd_buff[7]}},rd_buff[7:0]}),
							 .i5_in(0),
							 .i6_in(0),
							 .i7_in(0),
							 .sel_in(ctrl_load_mux_in));
mux8_32 mux_store (.y_out(wd_buff), 
							 .i0_in(wd_in), 
							 .i1_in({{16{1'b0}},wd_in[15:0]}), 
							 .i2_in({{16{wd_in[15]}},wd_in[15:0]}), 
						    .i3_in({{24{1'b0}},wd_in[7:0]}),
							 .i4_in({{24{wd_in[7]}},wd_in[7:0]}),
							 .i5_in(0),
							 .i6_in(0),
							 .i7_in(0),
							 .sel_in(ctrl_str_mux_in));*/
assign rd_out[7:0] = rd_buff[7:0];
assign wd_buff[7:0] = wd_in[7:0];

mux8 #8 mux_load_15_8 (
    .y_out(rd_out[15:8]), 
    .i0_in(rd_buff[15:8]), 
    .i1_in(rd_buff[15:8]), 
    .i2_in(rd_buff[15:8]), 
    .i3_in(8'b0), 
	 .i4_in({8{rd_buff[7]}}),
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
	 .sel_in(ctrl_load_mux_in)
    );
	 
mux8 #8 mux_load_23_16 (
    .y_out(rd_out[23:16]), 
    .i0_in(rd_buff[23:16]), 
    .i1_in(8'b0), 
    .i2_in({8{rd_buff[15]}}), 
    .i3_in(8'b0), 
    .i4_in({8{rd_buff[7]}}), 
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
    .sel_in(ctrl_load_mux_in)
    );
	 
	 mux8 #8 mux_load_31_24 (
    .y_out(rd_out[31:24]), 
    .i0_in(rd_buff[31:24]), 
    .i1_in(8'b0), 
    .i2_in({8{rd_buff[15]}}), 
    .i3_in(8'b0), 
    .i4_in({8{rd_buff[7]}}), 
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
    .sel_in(ctrl_load_mux_in)
    );
	 
	 mux8 #8 mux_str_15_8 (
    .y_out(wd_buff[15:8]), 
    .i0_in(wd_in[15:8]), 
    .i1_in(wd_in[15:8]), 
    .i2_in(wd_in[15:8]), 
    .i3_in(8'b0), 
	 .i4_in({8{wd_in[7]}}),
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
	 .sel_in(ctrl_str_mux_in)
    );
	 
mux8 #8 mux_str_23_16 (
    .y_out(wd_buff[23:16]), 
    .i0_in(wd_in[23:16]), 
    .i1_in(8'b0), 
    .i2_in({8{wd_in[15]}}), 
    .i3_in(8'b0), 
    .i4_in({8{wd_in[7]}}), 
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
    .sel_in(ctrl_str_mux_in)
    );
	 
	 mux8 #8 mux_str_31_24 (
    .y_out(wd_buff[31:24]), 
    .i0_in(wd_in[31:24]), 
    .i1_in(8'b0), 
    .i2_in({8{wd_in[15]}}), 
    .i3_in(8'b0), 
    .i4_in({8{wd_in[7]}}), 
	 .i5_in(8'b0), 
    .i6_in(8'b0), 
    .i7_in(8'b0),
    .sel_in(ctrl_str_mux_in)
    );
endmodule


