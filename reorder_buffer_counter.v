`include "reorder_buffer_define.v"
`include "timescale.v"
module reorder_buffer_counter(input clk_in,
										input reset_in,
										input reorder_buffer_shift_in,
										input reorder_buffer_update_in,
										input reorder_buffer_shift_2_in,
										output reg [`TAG_BITS_SIZE-1:0] reorder_buffer_status_out);
    
always@(posedge clk_in)
begin
	if(reset_in)
	begin
		reorder_buffer_status_out <= 4'b0;
	end
	else
	begin
		case ({reorder_buffer_shift_in,reorder_buffer_shift_2_in,reorder_buffer_update_in})
			3'b000 : 
				reorder_buffer_status_out <= reorder_buffer_status_out;
			3'b001 :
				reorder_buffer_status_out <= reorder_buffer_status_out + 2;
			3'b010 : 
				reorder_buffer_status_out <= reorder_buffer_status_out - 2;
			3'b011 : 
				reorder_buffer_status_out <= reorder_buffer_status_out;
			3'b100 : 
				reorder_buffer_status_out <= reorder_buffer_status_out - 1;
			3'b101 : 
				reorder_buffer_status_out <= reorder_buffer_status_out + 1 ;
			default:
				reorder_buffer_status_out <= reorder_buffer_status_out ;
		endcase
	end
end

endmodule
