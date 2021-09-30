
module redirect_hilo_ex (
	hilo_ex,
	alu_r1_mem,
	alu_r2_mem,
	alu_r1_wb,
	alu_r2_wb,
	rdata1_mem,
	rdata1_wb,
	hilo_mode_mem,
	hilo_mode_wb,
	hilo_read_ex,

	real_hilo_ex
);
	input [63:0] hilo_ex;
	input [31:0] alu_r1_mem;
	input [31:0] alu_r2_mem;
	input [31:0]alu_r1_wb;
	input [31:0]alu_r2_wb;
	input [31:0]rdata1_mem;
	input [31:0]rdata1_wb;
	input [1:0]hilo_mode_mem;
	input [1:0]hilo_mode_wb;
	input [1:0]hilo_read_ex;
	output reg[63:0] real_hilo_ex;
	always @(*) begin
		real_hilo_ex <= hilo_ex;
		if(hilo_read_ex==2'b01) begin
			if(hilo_mode_mem==2'b01) begin
				real_hilo_ex[31:0] <= rdata1_mem;
			end // if(hilo_mode_mem==2'b01)
			else if(hilo_mode_mem==2'b11) begin
				real_hilo_ex <= { alu_r2_mem, alu_r1_mem };
			end // else if(hilo_mode_mem==2'b11)
			else if(hilo_mode_mem==2'b00) begin
				if(hilo_mode_wb==2'b01) begin
					real_hilo_ex[31:0] <= rdata1_wb;
				end // if(hilo_mode_wb==2'b01)
				else if(hilo_mode_wb==2'b11) begin
					real_hilo_ex <= { alu_r2_wb,alu_r1_wb };
				end // else if(hilo_mode_wb==2'b11)
			end // else if(hilo_mode_mem==2'b00)
		end // if(hilo_read_ex==2'b01)
		else if(hilo_read_ex==2'b10) begin
			if(hilo_mode_mem==2'b10) begin
				real_hilo_ex[63:32] <= rdata1_mem;
			end // if(hilo_mode_mem==2'b10)
			else if(hilo_mode_mem==2'b11) begin
				real_hilo_ex <= { alu_r2_mem,alu_r1_mem };
			end // else if(hilo_mode_wb==2'b11)
			else if(hilo_mode_mem==2'b00) begin
				if(hilo_mode_wb==2'b10) begin
					real_hilo_ex[63:32] <= rdata1_wb;
				end // if(hilo_mode_wb==2'b01)
				else if(hilo_mode_wb==2'b11) begin
					real_hilo_ex <= { alu_r2_wb,alu_r1_wb } ;
				end // else if(hilo_mode_wb==2'b11)
			end // else if(hilo_mode_mem==2'b00)
		end // else if(hilo_read_ex==2'b10)
	end
endmodule