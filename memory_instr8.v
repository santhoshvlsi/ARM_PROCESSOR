`include "load_store_memory_stage_define.v"  
`include "timescale.v"

module memory_instr8 (	
	output [`MEM_DATA_BUS_WIDTH-1:0] rd_out,
	input [`ADDR_BUS_WIDTH-1:0] addr_in,
	input we_in,
	input [`MEM_DATA_BUS_WIDTH-1:0] wd_in,
	input clk_in,
	input reset_in
	);
//parameter ADDR_BUS_WIDTH = 32, MEM_DATA_BUS_WIDTH = 8;

   


reg [`MEM_DATA_BUS_WIDTH-1:0] arm_memory [0 : `DATA_MEM_SIZE-1];
//integer i;

initial
begin
$readmemh("data_mem8.bin",arm_memory);
/*for (i=42;i<`MEMORY_SIZE ;i=i+1)
begin
	arm_memory[i] = 0;
end*/ 
 
end

always @(posedge clk_in)
begin
	if (we_in)
	begin
		arm_memory[addr_in] <= wd_in;
	end
end
assign rd_out = arm_memory[addr_in] & {`MEM_DATA_BUS_WIDTH{reset_in}};

endmodule
