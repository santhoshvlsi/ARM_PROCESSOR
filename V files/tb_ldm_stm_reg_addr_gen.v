`timescale 1ns / 1ps

module tb_ldm_stm_reg_addr_gen;

	// Inputs
	reg clk_in;
	reg reset_in;
	reg ldm_stm_start_in;
	reg [15:0] data_in;
	reg [31:0] base_addr_in;
	reg [31:0] offset_in;
	reg [1:0] func_in;

	// Outputs
	wire [3:0] reg_addr_out;
	wire ldm_stm_en_out;
	wire [31:0] addr_to_mem_out;
	wire [31:0] data_to_reg_update_out;

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
    .clk_in(clk_in),
	 .reset_in(reset_in),
	 .base_addr_in(base_addr_in), 
    .offset_in(offset_in), 
    .func_in(func_in), 
	 .ldm_stm_en_in(ldm_stm_en_out),
    .ldm_stm_start_in(ldm_stm_start_in), 
    .swp_ctrl_S3_in(1'b0), 
	 .addr_to_mem_out(addr_to_mem_out), 
    .data_to_reg_update_out(data_to_reg_update_out)
    );
	
	initial begin
		// Initialize Inputs
		clk_in = 0;
		reset_in = 1;
		ldm_stm_start_in = 0;
		data_in = 0;
		base_addr_in = 0;
		offset_in = 0;
		func_in = 0;

		// Wait 100 ns for global reset to finish
		#105;
		reset_in <= 1'b0;  
		#10;
		ldm_stm_start_in = 1;
		data_in = 16'b0110_0111_0010_0001;
		base_addr_in = 10;
		offset_in = 5;
		func_in = 3'b00;
		#10;
		ldm_stm_start_in = 0;
		// Add stimulus here

	end
      
		always #5 clk_in = ~clk_in;
		
endmodule

