
module reg_din_select(
	alu_r_wb,
	pc_wb,
	DMout_wb,
	cp0_d1_wb,
	HI_wb,
	LO_wb,
	reg_din_sel,
	reg_din
    );

	input [31:0]alu_r_wb;
	input [31:0]pc_wb;
	input [31:0]DMout_wb;
	input [31:0]cp0_d1_wb;
	input [31:0]HI_wb;
	input [31:0]LO_wb;
	input [2:0]reg_din_sel;
	output reg[31:0]reg_din;

	always @(*) begin
		case(reg_din_sel)
			3'b000: begin
				reg_din <= alu_r_wb;
			end // 3'b000:
			3'b001: begin
				reg_din <= pc_wb + 8;//?????
			end // 3'b001:
			3'b010: begin
				reg_din <= DMout_wb;
			end // 3'b010:
			3'b011: begin
				reg_din <= cp0_d1_wb;
			end // 3'b011:
			3'b100: begin
				reg_din <= HI_wb;
			end // 3'b100:
			3'b101: begin
				reg_din <= LO_wb;
			end // 3'b101:
			default: begin
				reg_din <= 0;
			end // default:
		endcase // reg_din_sel
	end // always @(*)
endmodule