`include "timescale.v"


module mux16(y_out,i0_in,i1_in,i2_in,i3_in,i4_in,i5_in,i6_in,i7_in,i8_in,i9_in,i10_in,i11_in,i12_in,i13_in,
i14_in,i15_in,sel_in);
parameter BUS_WIDTH = 5;

output [BUS_WIDTH-1 : 0] y_out;
input [BUS_WIDTH-1 : 0] i0_in;
input [BUS_WIDTH-1 : 0] i1_in;
input [BUS_WIDTH-1 : 0] i2_in;
input [BUS_WIDTH-1 : 0] i3_in;
input [BUS_WIDTH-1 : 0] i4_in;
input [BUS_WIDTH-1 : 0] i5_in;
input [BUS_WIDTH-1 : 0] i6_in;
input [BUS_WIDTH-1 : 0] i7_in;
input [BUS_WIDTH-1 : 0] i8_in;
input [BUS_WIDTH-1 : 0] i9_in;
input [BUS_WIDTH-1 : 0] i10_in;
input [BUS_WIDTH-1 : 0] i11_in;
input [BUS_WIDTH-1 : 0] i12_in;
input [BUS_WIDTH-1 : 0] i13_in;
input [BUS_WIDTH-1 : 0] i14_in;
input [BUS_WIDTH-1 : 0] i15_in; 	
input [3:0] sel_in;

reg [BUS_WIDTH-1 : 0] y_out;
wire [BUS_WIDTH-1 : 0] i0_in;
wire [BUS_WIDTH-1 : 0] i1_in;
wire [BUS_WIDTH-1 : 0] i2_in;
wire [BUS_WIDTH-1 : 0] i3_in;
wire [BUS_WIDTH-1 : 0] i4_in;
wire [BUS_WIDTH-1 : 0] i5_in;
wire [BUS_WIDTH-1 : 0] i6_in;
wire [BUS_WIDTH-1 : 0] i7_in;
wire [BUS_WIDTH-1 : 0] i8_in;
wire [BUS_WIDTH-1 : 0] i9_in;
wire [BUS_WIDTH-1 : 0] i10_in;
wire [BUS_WIDTH-1 : 0] i11_in;
wire [BUS_WIDTH-1 : 0] i12_in;
wire [BUS_WIDTH-1 : 0] i13_in;
wire [BUS_WIDTH-1 : 0] i14_in;
wire [BUS_WIDTH-1 : 0] i15_in;
wire [3:0] sel_in;

always @(*)
begin
	case (sel_in)
		4'b0000 : y_out <= i0_in;
		4'b0001 : y_out <= i1_in;
		4'b0010 : y_out <= i2_in;
		4'b0011 : y_out <= i3_in;
		4'b0100 : y_out <= i4_in;
		4'b0101 : y_out <= i5_in;
		4'b0110 : y_out <= i6_in;
		4'b0111 : y_out <= i7_in;
		4'b1000 : y_out <= i8_in;
		4'b1001 : y_out <= i9_in;
		4'b1010 : y_out <= i10_in;
		4'b1011 : y_out <= i11_in;
		4'b1100 : y_out <= i12_in;
		4'b1101 : y_out <= i13_in;
		4'b1110 : y_out <= i14_in;
		4'b1111 : y_out <= i15_in;
	endcase
end

endmodule