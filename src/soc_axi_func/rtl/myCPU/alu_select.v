/*
**	作者：张鑫
**	功能：算术逻辑单元ALU的两个操作数的选择
**	原创
*/
module alu_select(
	alua_sel_ex,
	alub_sel_ex,
	rdata1_ex,
	rdata2_ex,
	extern_ex,

	alu_a,
	alu_b
    );

	input [1:0]alua_sel_ex;
	input [1:0]alub_sel_ex;
	input [31:0]rdata1_ex;
	input [31:0]rdata2_ex;
	input [31:0]extern_ex;
	output reg[31:0]alu_a;
	output reg[31:0]alu_b;

	always @(alua_sel_ex,rdata1_ex,rdata2_ex,extern_ex) begin
		case(alua_sel_ex)
			2'b00: begin
				alu_a <= rdata1_ex;
			end // 2'b00:
			2'b01: begin
				alu_a <= rdata2_ex;
			end // 2'b01:
			2'b10: begin
				alu_a <= extern_ex;
			end // 2'b10:
			default: begin
				alu_a <= 0;
			end // default:
		endcase
	end

	always @(alub_sel_ex,rdata2_ex,extern_ex) begin
		case(alub_sel_ex)
			2'b00: begin
				alu_b <= rdata2_ex;
			end // 2'b00:
			2'b01: begin
				alu_b <= extern_ex;
			end // 2'b01:
			2'b10: begin
				alu_b <= 0;
			end // 2'b10:
			2'b11: begin
				alu_b <= 16;
			end // 2'b11:
		endcase
	end
endmodule
