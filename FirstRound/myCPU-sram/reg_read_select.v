
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

	always @(*) begin
		case(r1_sel_id)
			1'b0: begin
				r1 <= rs_id;
			end // 2'b00:
			1'b1: begin
				r1 <= rt_id;
			end // 2'b01:
			default: begin
				r1 <= 0;
			end // default:
		endcase // r1_sel_id

		case(r2_sel_id)
			1'b0: begin
				r2 <= rs_id;
			end // 2'b00:
			1'b1: begin
				r2 <= rt_id;
			end // 2'b01:
			default: begin
				r2 <= 0;
			end // default:
		endcase // r2_sel_id
	end // always @(*)
endmodule
