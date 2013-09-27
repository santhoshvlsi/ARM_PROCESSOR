`include "timescale.v" 

module alu_decoder(
    input [3:0] alucontrol_in,
    output reg [7:0] control_signals_out
    );

parameter AND = 4'b0000;
parameter XOR = 4'b0001;
parameter SUB = 4'b0010;
parameter RSB = 4'b0011;
parameter ADD = 4'b0100;
parameter ADC = 4'b0101;
parameter SBC = 4'b0110;
parameter RSC = 4'b0111;
parameter TST = 4'b1000;
parameter TEQ = 4'b1001;
parameter CMP = 4'b1010;
parameter CMN = 4'b1011;
parameter ORR = 4'b1100;
parameter MOV = 4'b1101;
parameter BIC = 4'b1110;
parameter MVN = 4'b1111;

always @(alucontrol_in)
begin
	case(alucontrol_in)
		AND : control_signals_out <= 8'b00_00_0_010;
		XOR : control_signals_out <= 8'b00_00_0_100;
		SUB : control_signals_out <= 8'b01_01_0_000;
		RSB : control_signals_out <= 8'b01_10_0_000;
		ADD : control_signals_out <= 8'b00_00_0_000;
		ADC : control_signals_out <= 8'b10_00_0_000;
		SBC : control_signals_out <= 8'b11_01_0_000;
		RSC : control_signals_out <= 8'b11_10_0_000;
		TST : control_signals_out <= 8'b00_00_0_010;
		TEQ : control_signals_out <= 8'b00_00_0_100;
		CMP : control_signals_out <= 8'b01_01_0_000;
		CMN : control_signals_out <= 8'b00_00_0_000;
		ORR : control_signals_out <= 8'b00_00_0_001;
		MOV : control_signals_out <= 8'b00_00_0_101;
		BIC : control_signals_out <= 8'b00_00_1_010;
		MVN : control_signals_out <= 8'b00_00_0_011;
	endcase
end
		
endmodule
