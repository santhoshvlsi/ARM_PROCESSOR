`include "timescale.v" 

module register_with_reset(
									 data_in,
									 clk_in,
									 reset_in,
									 en_in,
									 data_out
								  );
parameter BUS_WIDTH = 32;

input [BUS_WIDTH-1:0] data_in;
input clk_in;
input en_in;
input reset_in;
output [BUS_WIDTH-1:0] data_out;

reg [BUS_WIDTH-1:0] data_out;

always@(posedge clk_in)
begin
	if(reset_in)
	begin
		data_out <= 0;
	end
	else if(en_in)
	begin
		data_out <= data_in;
	end
end

endmodule
