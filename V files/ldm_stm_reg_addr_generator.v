module ldm_stm_reg_addr_generator(
	 input clk_in,
	 input reset_in,
	 input ldm_stm_start_in,
	 input [15:0] data_in,
	 output [3:0] reg_addr_out,
	 output ldm_stm_en_out
	 );

wire [15:0] temp_data,temp_data_for_priority_encoder,reg_data_for_priority_encoder;
reg [15:0] temp_reg_for_priority_encoder;
reg ldm_stm_en;
wire ldm_stm_en_reg;
reg [3:0] reg_addr;

/******DATA_INPUT_FOR_PRIORITY_ENCODER******/
assign temp_data = data_in & temp_data_for_priority_encoder;
/******DATA_INPUT_FOR_PRIORITY_ENCODER******/

/******DATA_TO_AND_WITH_DATA_IN******/
assign temp_data_for_priority_encoder = (ldm_stm_start_in ? 16'b1111_1111_1111_1111 : 
(ldm_stm_en_out ? reg_data_for_priority_encoder : 0));
/******DATA_TO_AND_WITH_DATA_IN******/

/******PRIORITY_ENCODER******/
always@(*)
begin
	if(temp_data[0])
	begin
		{ldm_stm_en,reg_addr} = 5'b10000;
		temp_reg_for_priority_encoder = 16'b1111_1111_1111_1110;
	end
	else if(temp_data[1])
	begin
		{ldm_stm_en,reg_addr} = 5'b10001;
		temp_reg_for_priority_encoder = 16'b1111_1111_1111_1100;
	end
	else if(temp_data[2])
	begin
		{ldm_stm_en,reg_addr} = 5'b10010;
		temp_reg_for_priority_encoder = 16'b1111_1111_1111_1000;
	end
	else if(temp_data[3])
	begin
		{ldm_stm_en,reg_addr} = 5'b10011;
		temp_reg_for_priority_encoder = 16'b1111_1111_1111_0000;
	end
	else if(temp_data[4])
	begin
		{ldm_stm_en,reg_addr} = 5'b10100;
		temp_reg_for_priority_encoder = 16'b1111_1111_1110_0000;
	end
	else if(temp_data[5])
	begin
		{ldm_stm_en,reg_addr} = 5'b10101;
		temp_reg_for_priority_encoder = 16'b1111_1111_1100_0000;
	end
	else if(temp_data[6])
	begin
		{ldm_stm_en,reg_addr} = 5'b10110;
		temp_reg_for_priority_encoder = 16'b1111_1111_1000_0000;
	end
	else if(temp_data[7])
	begin
		{ldm_stm_en,reg_addr} = 5'b10111;
		temp_reg_for_priority_encoder = 16'b1111_1111_0000_0000;
	end
	else if(temp_data[8])
	begin
		{ldm_stm_en,reg_addr} = 5'b11000;
		temp_reg_for_priority_encoder = 16'b1111_1110_0000_0000;
	end
	else if(temp_data[9])
	begin
		{ldm_stm_en,reg_addr} = 5'b11001;
		temp_reg_for_priority_encoder = 16'b1111_1100_0000_0000;
	end
	else if(temp_data[10])
	begin
		{ldm_stm_en,reg_addr} = 5'b11010;
		temp_reg_for_priority_encoder = 16'b1111_1000_0000_0000;
	end
	else if(temp_data[11])
	begin
		{ldm_stm_en,reg_addr} = 5'b11011;
		temp_reg_for_priority_encoder = 16'b1111_0000_0000_0000;
	end
	else if(temp_data[12])
	begin
		{ldm_stm_en,reg_addr} = 5'b11100;
		temp_reg_for_priority_encoder = 16'b1110_0000_0000_0000;
	end
	else if(temp_data[13])
	begin
		{ldm_stm_en,reg_addr} = 5'b11101;
		temp_reg_for_priority_encoder = 16'b1100_0000_0000_0000;
	end
	else if(temp_data[14])
	begin
		{ldm_stm_en,reg_addr} = 5'b11110;
		temp_reg_for_priority_encoder = 16'b1000_0000_0000_0000;
	end
	else if(temp_data[15])
	begin
		{ldm_stm_en,reg_addr} = 5'b11111;
		temp_reg_for_priority_encoder = 16'b0000_0000_0000_0000;
	end
	else
	begin
		{ldm_stm_en,reg_addr} = 5'b01111;
		temp_reg_for_priority_encoder = 16'b0000_0000_0000_0000;
	end
end
/******PRIORITY_ENCODER******/

register_with_reset #16 reg_temp_reg_for_priority_encoder (
		 .data_in(temp_reg_for_priority_encoder), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(ldm_stm_en), 
		 .data_out(reg_data_for_priority_encoder)
		 );
/*register_with_reset #1 reg_ldm_stm_en (
		 .data_in(ldm_stm_en), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(1'b1), 
		 .data_out(ldm_stm_en_out)
		 );*/

assign ldm_stm_en_out = ldm_stm_en;
assign reg_addr_out = reg_addr;

/*register_with_reset #4 reg_reg_addr (
		 .data_in(reg_addr), 
		 .clk_in(clk_in), 
		 .reset_in(reset_in), 
		 .en_in(ldm_stm_en), 
		 .data_out(reg_addr_out)
		 );*/

endmodule
