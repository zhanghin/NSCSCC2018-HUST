
//simulated

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
			default: begin
				rw <= 0;
			end // default:
		endcase // rw_sel_id
		//$display("rw_sel_id<= %2h,rw<= %2h",rw_sel_id,rw);
	end // always @(*)
endmodule