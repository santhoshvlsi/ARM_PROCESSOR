`timescale 1ns / 1ps

module tb_ldm_stm_reg_addr_gen;

	// Inputs
	reg clk_in;
	reg reset_in;
	reg ldm_stm_start_in;
	reg [15:0] data_in;
	reg [31:0] base_addr_in;

	// Outputs
	wire [3:0] reg_addr_out;
	wire ldm_stm_en_out;

	// Instantiate the Unit Under Test (UUT)
	ldm_stm_reg_addr_generator uut (
		.clk_in(clk_in), 
		.reset_in(reset_in), 
		.ldm_stm_start_in(ldm_stm_start_in), 
		.data_in(data_in), 
		.reg_addr_out(reg_addr_out), 
		.ldm_stm_en_out(ldm_stm_en_out)
	);
	
	mem_addr_calc address_calculator (
    .base_addr_in(base_addr_in), 
    .offset_in(offset_final), 
    .func_in(add_calc_func), 
	 .ldm_stm_en_in(ldm_stm_en_in),
    .ldm_stm_start_in(ldm_stm_start_in), 
    .swp_ctrl_S3_in(ld_str_multiple_en), 
	 .swp_ctrl_S3_in(1'b0),
    .addr_to_mem_out(addr_to_mem_frm_mem_addr_calc), 
    .data_to_reg_update_out(rn_data_out)
    );
	
	initial begin
		// Initialize Inputs
		clk_in = 0;
		reset_in = 1;
		ldm_stm_start_in = 0;
		data_in = 0;

		// Wait 100 ns for global reset to finish
		#105;
		reset_in <= 1'b0;  
		#10;
		ldm_stm_start_in = 1;
		data_in = 16'b0110_0111_0010_0001;
		#10;
		ldm_stm_start_in = 0;
		// Add stimulus here

	end
      
		always #5 clk_in = ~clk_in;
		
endmodule

