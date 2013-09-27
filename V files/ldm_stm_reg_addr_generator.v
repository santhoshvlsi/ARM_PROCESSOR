module ldm_stm_reg_addr_generator(
	 input clk_in,
	 input reset_in,
	 input ldm_stm_start_in,
	 input [15:0] data_in,
	 output [3:0] reg_addr_out,
	 output ldm_stm_stop_out
	 );

wire [15:0] temp_data,temp_data_for_priority_encoder,reg_data_for_priority_encoder;
reg [3:0] temp_reg_addr;
reg [15:0] temp_reg_for_priority_encoder;

/******DATA_INPUT_FOR_PRIORITY_ENCODER******/
assign temp_data = data_in & temp_reg_for_priority_encoder;
/******DATA_INPUT_FOR_PRIORITY_ENCODER******/

/******DATA_TO_AND_WITH_DATA_IN******/
assign temp_data_for_priority_encoder = ldm_stm_start_in ? 16'b1111_1111_1111_1111 : 
reg_data_for_priority_encoder;
/******DATA_TO_AND_WITH_DATA_IN******/

/******PRIORITY_ENCODER******/
always@(*)
begin
	if(temp_data[0])
	begin
		temp_reg_addr = 4'b0000;
		temp_reg_for_priority_encoder = 15'b1111_1111_1111_1110;
	end
	else if(temp_data[1])
	begin
		temp_reg_addr = 4'b0001;
		temp_reg_for_priority_encoder = 15'b1111_1111_1111_1100;
	end
	else if(temp_data[2])
	begin
		temp_reg_addr = 4'b0010;
		temp_reg_for_priority_encoder = 15'b1111_1111_1111_1000;
	end
	else if(temp_data[3])
	begin
		temp_reg_addr = 4'b0011;
		temp_reg_for_priority_encoder = 15'b1111_1111_1111_0000;
	end
	else if(temp_data[4])
	begin
		temp_reg_addr = 4'b0100;
		temp_reg_for_priority_encoder = 15'b1111_1111_1110_0000;
	end
	else if(temp_data[5])
	begin
		temp_reg_addr = 4'b0101;
		temp_reg_for_priority_encoder = 15'b1111_1111_1100_0000;
	end
	else if(temp_data[6])
	begin
		temp_reg_addr = 4'b0110;
		temp_reg_for_priority_encoder = 15'b1111_1111_1000_0000;
	end
	else if(temp_data[7])
	begin
		temp_reg_addr = 4'b0111;
		temp_reg_for_priority_encoder = 15'b1111_1111_0000_0000;
	end
	else if(temp_data[8])
	begin
		temp_reg_addr = 4'b1000;
		temp_reg_for_priority_encoder = 15'b1111_1110_0000_0000;
	end
	else if(temp_data[9])
	begin
		temp_reg_addr = 4'b1001;
		temp_reg_for_priority_encoder = 15'b1111_1100_0000_0000;
	end
	else if(temp_data[10])
	begin
		temp_reg_addr = 4'b1010;
		temp_reg_for_priority_encoder = 15'b1111_1000_0000_0000;
	end
	else if(temp_data[11])
	begin
		temp_reg_addr = 4'b1011;
		temp_reg_for_priority_encoder = 15'b1111_0000_0000_0000;
	end
	else if(temp_data[12])
	begin
		temp_reg_addr = 4'b1100;
		temp_reg_for_priority_encoder = 15'b1110_0000_0000_0000;
	end
	else if(temp_data[13])
	begin
		temp_reg_addr = 4'b1101;
		temp_reg_for_priority_encoder = 15'b1100_0000_0000_0000;
	end
	else if(temp_data[14])
	begin
		temp_reg_addr = 4'b1110;
		temp_reg_for_priority_encoder = 15'b1000_0000_0000_0000;
	end
	else
	begin
		temp_reg_addr = 4'b1111;
		temp_reg_for_priority_encoder = 15'b0000_0000_0000_0000;
	end
end
/******PRIORITY_ENCODER******/


								  
assign ldm_stm_stop_out = (~temp[14][4] & ~temp[14][3] & ~temp[14][2] & ~temp[14][1] & ~temp[14][0])
& (data_buff[4] | data_buff[3] | data_buff[2] | data_buff[1] | data_buff[0]);


endmodule
