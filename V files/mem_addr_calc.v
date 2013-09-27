`timescale 1ns / 1ps

module mem_addr_calc(
    input [31:0] base_addr_in,
    input [31:0] offset_in,
    input [2:0] func_in,
	 input ctrl_ldm_stm_start_S3_in,
	 input swp_ctrl_S3_in,
	 output [31:0] addr_to_mem_out//,
    //output [31:0] data_to_reg_update_out
	 //output ldm_stm_inc_dec_out
    );

parameter ADD = 5'b110;
parameter SUB = 5'b100;
parameter PRE_ADD = 5'b111;
parameter PRE_SUB = 5'b101;
parameter POST_ADD = 5'b010;
parameter POST_SUB = 5'b000;

reg [31:0] addr_to_mem_buff;
reg [31:0] data_to_reg_update_buff;
wire [31:0] addr_to_mem;
wire [31:0] base_addr_inc;
wire [31:0] base_addr_dec;
wire [31:0] data_to_reg_update;

always@(*)
begin
	case (func_in)
		ADD : 
		begin
			addr_to_mem_buff = base_addr_in + offset_in;
			data_to_reg_update_buff = base_addr_in + offset_in;
		end
		SUB : 
		begin
			addr_to_mem_buff = base_addr_in - offset_in;
			data_to_reg_update_buff = base_addr_in - offset_in;
		end
		PRE_ADD : 
		begin
			addr_to_mem_buff = base_addr_in + offset_in;
			data_to_reg_update_buff = base_addr_in + offset_in;
		end
		PRE_SUB : 
		begin
			addr_to_mem_buff = base_addr_in - offset_in;
			data_to_reg_update_buff = base_addr_in - offset_in;
		end
		POST_ADD :
		begin
			addr_to_mem_buff = base_addr_in;
			data_to_reg_update_buff = base_addr_in + offset_in;
		end
		POST_SUB : 
		begin
			addr_to_mem_buff = base_addr_in;
			data_to_reg_update_buff = base_addr_in - offset_in;
		end
		default : 
		begin
			addr_to_mem_buff = 0;
			data_to_reg_update_buff = 0;
		end
	endcase
end

assign addr_to_mem_out = addr_to_mem;
assign addr_to_mem = ctrl_ldm_stm_start_S3_in ? (func_in[1] ? (func_in[2] ? base_addr_inc : 
base_addr_in) : (func_in[2] ? base_addr_dec : base_addr_in)) : (swp_ctrl_S3_in ? base_addr_in : 
addr_to_mem_buff);
assign base_addr_inc = base_addr_in + 32'h4;
assign base_addr_dec = base_addr_in - 32'h4;
//assign data_to_reg_update_out = instr_exec_in ? data_to_reg_update : 0;
assign data_to_reg_update = (ctrl_ldm_stm_start_S3_in & func_in[0]) ? base_addr_in : 
data_to_reg_update_buff;
//assign ldm_stm_inc_dec_out = func_in[1];

endmodule
