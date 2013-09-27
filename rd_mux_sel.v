`include "timescale.v"

module reg_mux_sel(input tag_matched_with_alu_pipe1_final_in,
						input tag_matched_with_alu_pipe2_final_in,
						input tag_matched_with_load_store_pipe3_final_in,
						input tag_matched_with_branch_pipe4_final_in,
						output reg [1:0] reg_data_mux_sel_out
    );

always@(*)
begin
	case({tag_matched_with_alu_pipe1_final_in,tag_matched_with_alu_pipe2_final_in,
	tag_matched_with_load_store_pipe3_final_in,tag_matched_with_branch_pipe4_final_in})
		4'b0001 : 
		begin
			reg_data_mux_sel_out = 2'b11;
		end
		4'b0010 : 
		begin
			reg_data_mux_sel_out = 2'b10;
		end
		4'b0100 : 
		begin
			reg_data_mux_sel_out = 2'b01;
		end
		4'b1000 : 
		begin
			reg_data_mux_sel_out = 2'b00;
		end
		default : 
		begin
			reg_data_mux_sel_out = 2'b00;
		end
	endcase
end

endmodule
