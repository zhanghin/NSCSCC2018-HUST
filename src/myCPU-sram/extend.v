
//simulated

module extend(
	ext_sel,
	shamt,
	imm16,
	imm32
    );

	input [1:0] ext_sel;
	input [4:0] shamt;
	input [15:0] imm16;

	output reg[31:0] imm32;
	wire [15:0] sign;
	assign sign = {imm16[15],imm16[15],imm16[15],imm16[15],imm16[15],imm16[15],
			imm16[15],imm16[15],imm16[15],imm16[15],imm16[15],imm16[15],
			imm16[15],imm16[15],imm16[15],imm16[15]};

	always @(*) begin
		case(ext_sel)
			2'b00: begin
				imm32 = {sign,imm16};
			end // 2'b00:
			2'b01: begin
				imm32 = {16'h0000,imm16};
			end // 2'b01:
			2'b10: begin
				imm32 = {27'h0000000,shamt};
			end // 2'b10:
			default:
				imm32 = 0;
		endcase // ext_sel
	end // always @(*)

	//reg number unsigned extendsion???
endmodule

