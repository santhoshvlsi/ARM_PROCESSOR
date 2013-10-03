`timescale 1ns / 1ps

module mem_addr_calc(
    input [31:0] base_addr_in,
    input [31:0] offset_in,
    input [2:0] func_in,
	 input ldm_stm_en_in,
	 input ldm_stm_start_in,
	 input swp_ctrl_S3_in,
	 output [31:0] addr_to_mem_out,
    output [31:0] data_to_reg_update_out
	 );

parameter NO_MULTIPLE_POST_SUB = 4'b000;
parameter MULTIPLE_POST_SUB = 4'b110;
parameter NO_MULTIPLE_POST_ADD = 4'b001;
parameter MULTIPLE_POST_ADD = 4'b111;
parameter NO_MULTIPLE_PRE_SUB = 4'b010;
parameter MULTIPLE_PRE_SUB = 4'b100;
parameter NO_MULTIPLE_PRE_ADD = 4'b011;
parameter MULTIPLE_PRE_ADD = 4'b101;




reg [31:0] addr_to_mem_buff;
reg [31:0] data_to_reg_update_buff;
wire [3:0] func;
wire [31:0] base_reg_for_add,base_addr_frm_reg;

assign func = {ldm_stm_en_in,func_in};

assign base_reg_for_add = ldm_stm_en_in ? (ldm_stm_start_in ? base_addr_in : base_addr_frm_reg) : 
base_addr_in;

always@(*)
begin
	case (func)
		NO_MULTIPLE_POST_SUB : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add - offset_in;
		end
		NO_MULTIPLE_POST_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add + offset_in;
		end
		NO_MULTIPLE_PRE_SUB :
		begin
			addr_to_mem_buff = base_reg_for_add - offset_in;
			data_to_reg_update_buff = base_reg_for_add - offset_in;
		end
		NO_MULTIPLE_PRE_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add + offset_in;
			data_to_reg_update_buff = base_reg_for_add + offset_in;
		end
		MULTIPLE_PRE_SUB : 
		begin
			addr_to_mem_buff = base_reg_for_add - offset_in;
			data_to_reg_update_buff = base_reg_for_add - offset_in;
		end
		MULTIPLE_PRE_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add + offset_in;
			data_to_reg_update_buff = base_reg_for_add + offset_in;
		end
		MULTIPLE_POST_SUB :
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add - offset_in;
		end
		MULTIPLE_POST_ADD : 
		begin
			addr_to_mem_buff = base_reg_for_add;
			data_to_reg_update_buff = base_reg_for_add + offset_in;
		end
		default : 
		begin
			addr_to_mem_buff = 0;
			data_to_reg_update_buff = 0;
		end
	endcase
end

register_with_reset #32 reg_base_reg_for_add (
		 .data_in(base_reg_for_add), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(base_addr_frm_reg)
		 );

assign addr_to_mem_out = swp_ctrl_S3_in ? base_addr_in : addr_to_mem_buff;
assign data_to_reg_update_out = data_to_reg_update_buff;

endmodule
