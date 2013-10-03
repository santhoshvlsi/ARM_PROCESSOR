`timescale 1ns / 1ps

module mem_addr_calc(
	 input clk_in,
	 input reset_in,
    input [31:0] base_addr_in,
    input [31:0] offset_in,
    input [1:0] func_in,
	 input ldm_stm_en_in,
	 input ldm_stm_start_in,
	 input swp_ctrl_S3_in,
	 output [31:0] addr_to_mem_out,
    output [31:0] data_to_reg_update_out
	 );

parameter NO_MULTIPLE_POST_SUB = 3'b000;
parameter MULTIPLE_POST_SUB = 3'b110;
parameter NO_MULTIPLE_POST_ADD = 3'b001;
parameter MULTIPLE_POST_ADD = 3'b111;
parameter NO_MULTIPLE_PRE_SUB = 3'b010;
parameter MULTIPLE_PRE_SUB = 3'b100;
parameter NO_MULTIPLE_PRE_ADD = 3'b011;
parameter MULTIPLE_PRE_ADD = 3'b101;




reg [31:0] addr_to_mem_buff;
reg [31:0] data_to_reg_update_buff;
wire [3:0] func;
wire [31:0] base_reg_for_add,base_addr_frm_reg;
wire [31:0] offset;

assign func = {ldm_stm_en_in,func_in};

assign base_reg_for_add = ldm_stm_en_in ? (ldm_stm_start_in ? base_addr_in : base_addr_frm_reg) : 
base_addr_in;
assign offset = ldm_stm_en_in ? (ldm_stm_start_in ? offset_in : 4) : offset_in;

always@(*)
begin
	case (func)
		NO_MULTIPLE_POST_SUB : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add - offset;
		end
		NO_MULTIPLE_POST_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add + offset;
		end
		NO_MULTIPLE_PRE_SUB :
		begin
			addr_to_mem_buff = base_reg_for_add - offset;
			data_to_reg_update_buff = base_reg_for_add - offset;
		end
		NO_MULTIPLE_PRE_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add + offset;
			data_to_reg_update_buff = base_reg_for_add + offset;
		end
		MULTIPLE_PRE_SUB : 
		begin
			addr_to_mem_buff = base_reg_for_add - offset;
			data_to_reg_update_buff = base_reg_for_add - offset;
		end
		MULTIPLE_PRE_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add + offset;
			data_to_reg_update_buff = base_reg_for_add + offset;
		end
		MULTIPLE_POST_SUB :
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add - offset;
		end
		MULTIPLE_POST_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add + offset;
		end
		default : 
		begin
			addr_to_mem_buff = 0;
			data_to_reg_update_buff = 0;
		end
	endcase
end

register_with_reset #32 reg_base_reg_for_add (
		 .data_in(addr_to_mem_buff), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(base_addr_frm_reg)
		 );

assign addr_to_mem_out = swp_ctrl_S3_in ? base_addr_in : addr_to_mem_buff;
assign data_to_reg_update_out = data_to_reg_update_buff;

endmodule
