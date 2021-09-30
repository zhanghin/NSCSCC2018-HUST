
module rst_delay(
	clk,
	rst_in,
	rst_out
	);
	input clk;
	input rst_in;
	output reg rst_out;
	always @(posedge clk) begin
		rst_out <= rst_in;
	end
endmodule