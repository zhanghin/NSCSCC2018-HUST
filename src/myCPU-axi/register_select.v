/*
**	作者：张鑫
**	功能：读寄存器编号选择
**	原创
*/
module reg_read_select(
	rs_id,
	rt_id,
	r1_sel_id,
	r2_sel_id,
	
	r1,
	r2
    );
	input [4:0]rs_id;
	input [4:0]rt_id;
	input r1_sel_id;
	input r2_sel_id;
	output reg[4:0]r1;
	output reg[4:0]r2;

	always @(r1_sel_id,rs_id,rt_id) begin
		case(r1_sel_id)
			1'b0: begin
				r1 <= rs_id;
			end // 2'b00:
			1'b1: begin
				r1 <= rt_id;
			end // 2'b01:
		endcase
	end

	always @(r2_sel_id,rs_id,rt_id) begin
		case(r2_sel_id)
			1'b0: begin
				r2 <= rs_id;
			end // 2'b00:
			1'b1: begin
				r2 <= rt_id;
			end // 2'b01:
		endcase
	end
endmodule

/*
**	作者：张鑫
**	功能：写寄存器编号选择
**	原创
*/
module reg_write_select(
	rt_id,
	rd_id,
	rw_sel_id,
	rw
    );

	input [4:0]rt_id;
	input [4:0]rd_id;
	input [1:0]rw_sel_id;
	output reg[4:0]rw;

	always @(*) begin
		case(rw_sel_id)
			2'b00:begin
				rw <= 31;
			end // 2'b00:
			2'b01: begin
				rw <= rt_id;
			end // 2'b01:
			2'b10: begin
				rw <= rd_id;
			end // 2'b10:
		endcase
	end
endmodule

/*
**	作者：张鑫
**	功能：通用寄存器写入的数据选择
**	原创
*/
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
			3'b110: begin
				reg_din <= alu_r_wb;
			end // 3'b000:
			3'b001: begin
				reg_din <= pc_wb + 8;
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