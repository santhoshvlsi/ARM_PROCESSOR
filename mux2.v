`include "timescale.v" 


module mux2 (y_out,i0_in,i1_in,sel_in);
parameter BUS_WIDTH = 32;

output [BUS_WIDTH-1 : 0] y_out;
input [BUS_WIDTH-1 : 0] i0_in;
input [BUS_WIDTH-1 : 0] i1_in; 	
input sel_in;

reg [BUS_WIDTH-1 : 0] y_out;
wire[BUS_WIDTH-1 : 0] i0_in;
wire[BUS_WIDTH-1 : 0] i1_in;
wire sel_in;

always @(*)
begin
	case (sel_in)
		1'b0 : y_out <= i0_in;
		1'b1 : y_out <= i1_in;
	endcase
end
endmodule
