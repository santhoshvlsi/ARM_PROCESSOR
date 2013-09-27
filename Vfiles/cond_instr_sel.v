`include "timescale.v" 

module cond_instr_sel(
    input [3:0] cond_in,
    input [3:0] flag_register_in,
    output reg instr_exec_out
    );
parameter EQ = 4'b0000;
parameter NE = 4'b0001;
parameter CS = 4'b0010;
parameter CC = 4'b0011;
parameter MI = 4'b0100;
parameter PL = 4'b0101;
parameter VS = 4'b0110;
parameter VC = 4'b0111;
parameter HI = 4'b1000;
parameter LS = 4'b1001;
parameter GE = 4'b1010;
parameter LT = 4'b1011;
parameter GRT = 4'b1100;
parameter LE = 4'b1101;
parameter AL = 4'b1110;
parameter NV = 4'b1111;
always@(*)
begin
	case(cond_in)
		EQ : 
		begin
			instr_exec_out = flag_register_in[2];
		end
		NE : 
		begin
			instr_exec_out = ~(flag_register_in[2]);
		end
		CS : 
		begin
			instr_exec_out = flag_register_in[1];
		end
		CC : 
		begin
			instr_exec_out = ~(flag_register_in[1]);
		end
		MI :  
		begin
			instr_exec_out = flag_register_in[3];
		end
		PL :
		begin
			instr_exec_out = ~flag_register_in[3];
		end
		VS : 
		begin
			instr_exec_out = flag_register_in[0];
		end
		VC :
		begin
			instr_exec_out = ~flag_register_in[0];
		end
		HI :
		begin
			instr_exec_out = flag_register_in[1] & ~(flag_register_in[2]);
		end
		LS :
		begin
			instr_exec_out = ~(flag_register_in[1]) | flag_register_in[2];
		end
		GE : 
		begin
			instr_exec_out = (flag_register_in[3] & flag_register_in[0]) | (~(flag_register_in[3]) & ~(flag_register_in[0]));
		end
		LT : 
		begin
			instr_exec_out = (flag_register_in[3] & ~(flag_register_in[0])) | (~(flag_register_in[3]) & flag_register_in[0]);
		end
		GRT :
		begin
			instr_exec_out = flag_register_in[2] & ((flag_register_in[3] & flag_register_in[0]) | (~(flag_register_in[3]) & ~(flag_register_in[0])));
		end
		LE : 
		begin
			instr_exec_out = flag_register_in[2] | ((flag_register_in[3] & ~(flag_register_in[0])) | (~(flag_register_in[3]) & flag_register_in[0]));
		end
		AL : 
		begin
			instr_exec_out = 1'b1;
		end
		default : 
		begin
			instr_exec_out = 1'b0;
		end
	endcase
end
endmodule
