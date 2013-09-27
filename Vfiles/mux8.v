`include "timescale.v"


module mux8(y_out,i0_in,i1_in,i2_in,i3_in,i4_in,i5_in,i6_in,i7_in,sel_in);
parameter BUS_WIDTH = 4;

output [BUS_WIDTH-1 : 0] y_out;
input [BUS_WIDTH-1 : 0] i0_in;
input [BUS_WIDTH-1 : 0] i1_in;
input [BUS_WIDTH-1 : 0] i2_in;
input [BUS_WIDTH-1 : 0] i3_in;
input [BUS_WIDTH-1 : 0] i4_in;
input [BUS_WIDTH-1 : 0] i5_in;
input [BUS_WIDTH-1 : 0] i6_in;
input [BUS_WIDTH-1 : 0] i7_in; 	
input [2:0] sel_in;

reg [BUS_WIDTH-1 : 0] y_out;
wire [BUS_WIDTH-1 : 0] i0_in;
wire [BUS_WIDTH-1 : 0] i1_in;
wire [BUS_WIDTH-1 : 0] i2_in;
wire [BUS_WIDTH-1 : 0] i3_in;
wire [BUS_WIDTH-1 : 0] i4_in;
wire [BUS_WIDTH-1 : 0] i5_in;
wire [BUS_WIDTH-1 : 0] i6_in;
wire [BUS_WIDTH-1 : 0] i7_in;
wire [2:0] sel_in;

always @(*)
begin
	case (sel_in)
		3'b000 : y_out <= i0_in;
		3'b001 : y_out <= i1_in;
		3'b010 : y_out <= i2_in;
		3'b011 : y_out <= i3_in;
		3'b100 : y_out <= i4_in;
		3'b101 : y_out <= i5_in;
		3'b110 : y_out <= i6_in;
		3'b111 : y_out <= i7_in;
	endcase
end
endmodule
