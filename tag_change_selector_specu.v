`include "timescale.v"
`include "reorder_buffer_define.v"
module tag_change_selector_specu(
											input [`REORDER_BUFFER_SIZE-1:0] tag_change_pipe_in,
											output reg [`REORDER_BUFFER_SIZE-1:0] tag_to_change_selector_out
    );

always@(*)
begin
	case(tag_change_pipe_in)
		`REORDER_BUFFER_SIZE'b0000_0000_0000_0001 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_0000;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0000_0010 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_0001;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0000_0100 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_0011;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0000_1000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_0111;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0001_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0010_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0001_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_0100_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0011_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0000_1000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0111_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0001_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0010_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0001_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_0100_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0011_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0000_1000_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0111_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0001_0000_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_1111_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0010_0000_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0001_1111_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b0100_0000_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0011_1111_1111_1111;
		end
		`REORDER_BUFFER_SIZE'b1000_0000_0000_0000 : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0111_1111_1111_1111;
		end
		default : 
		begin
			tag_to_change_selector_out = `REORDER_BUFFER_SIZE'b0000_0000_0000_0000;
		end
	endcase
end
		
endmodule
