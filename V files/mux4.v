`include "timescale.v" 


module mux4 (y_out,i0_in,i1_in,i2_in,i3_in,sel_in);
parameter BUS_WIDTH = 32;

output [BUS_WIDTH-1 : 0] y_out;
input [BUS_WIDTH-1 : 0] i0_in;
input [BUS_WIDTH-1 : 0] i1_in;
input [BUS_WIDTH-1 : 0] i2_in;
input [BUS_WIDTH-1 : 0] i3_in; 	
input [1:0] sel_in;

reg [BUS_WIDTH-1 : 0] y_out;
wire [BUS_WIDTH-1 : 0] i0_in;
wire [BUS_WIDTH-1 : 0] i1_in;
wire [BUS_WIDTH-1 : 0] i2_in;
wire [BUS_WIDTH-1 : 0] i3_in;
wire [1:0] sel_in;

always @(*)
begin
	case (sel_in)
		2'b00 : y_out <= i0_in;
		2'b01 : y_out <= i1_in;
		2'b10 : y_out <= i2_in;
		2'b11 : y_out <= i3_in;
	endcase
end
endmodule
