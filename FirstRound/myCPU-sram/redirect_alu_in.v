
module redirect_alu_in (
	real_rdata1_ex,
	real_rdata2_ex,

	rdata1_ex,
	rdata2_ex,
	alu_r1_mem,
	reg_din_wb,
	hilo_mem,
	hilo_wb,
	cp0_data_mem,
	cp0_data_wb,
	r1_r_ex,
	r2_r_ex,
	r1_ex,
	r2_ex,
	reg_we_direct_mem,
	reg_we_direct_wb,
	rw_mem,
	rw_wb
);
	input [31:0]rdata1_ex;
	input [31:0]rdata2_ex;
	input [31:0]alu_r1_mem;
	input [31:0]reg_din_wb;
	input [63:0]hilo_mem;
	input [63:0]hilo_wb;
	input [31:0]cp0_data_mem;
	input [31:0]cp0_data_wb;
	input r1_r_ex;
	input r2_r_ex;
	input [4:0]r1_ex;
	input [4:0]r2_ex;
	input [3:0]reg_we_direct_mem;
	input [3:0]reg_we_direct_wb;
	input [4:0]rw_mem;
	input [4:0]rw_wb;
	output reg[31:0]real_rdata1_ex;
	output reg[31:0]real_rdata2_ex;

	wire r_eq_w[3:0];
	assign r_eq_w[3] = r1_r_ex & (r1_ex==rw_mem) & (rw_mem!=0);
	assign r_eq_w[2] = r2_r_ex & (r2_ex==rw_mem) & (rw_mem!=0);
	assign r_eq_w[1] = r1_r_ex & (r1_ex==rw_wb) & (rw_wb!=0);
	assign r_eq_w[0] = r2_r_ex & (r2_ex==rw_wb) & (rw_wb!=0);

/*	always @(posedge clk) begin
		$display("r_eq_w = ,reg_we_direct_mem = %8h,reg_we_direct_wb = %h"
			,reg_we_direct_mem,reg_we_direct_wb);
		$display("rdata1_ex=%8h,rdata2_ex=%8h,alu_r1_mem=%8h,reg_din_wb=%8h"
			,rdata1_ex,rdata2_ex,alu_r1_mem,reg_din_wb);
		$display("real_rdata1_ex = %8h,real_rdata2_ex = %8h"
			,real_rdata1_ex,real_rdata2_ex);
	end*/

	always @(*) begin
		real_rdata1_ex <= rdata1_ex;
		real_rdata2_ex <= rdata2_ex;

		if(reg_we_direct_wb==4'b0001) begin
			if(r_eq_w[1]) begin
				real_rdata1_ex <= reg_din_wb;
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[1])
			if(r_eq_w[0]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= reg_din_wb;
			end // else if(r_eq_w[0])
		end // if(reg_we_direct_wb==4'b0001)
		else if(reg_we_direct_wb==4'b0010) begin
			if(r_eq_w[1]) begin
				real_rdata1_ex <= hilo_wb[31:0];
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[1])
			if(r_eq_w[0]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= hilo_wb[31:0];
			end // else if(r_eq_w[0])
		end // else if(reg_we_direct_wb==4'b0010)
		else if(reg_we_direct_wb==4'b0100) begin
			if(r_eq_w[1]) begin
				real_rdata1_ex <= hilo_wb[63:32];
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[1])
			if(r_eq_w[0]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= hilo_wb[63:32];
			end // else if(r_eq_w[0])
		end // else if(reg_we_direct_wb==4'b0100)
		else if(reg_we_direct_wb==4'b1000) begin
			if(r_eq_w[1]) begin
				real_rdata1_ex <= cp0_data_wb;
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[1])
			if(r_eq_w[0]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= cp0_data_wb;
			end // else if(r_eq_w[0])
		end // else if(reg_we_direct_wb==4'b1000)

		if(reg_we_direct_mem==4'b0001) begin
			if(r_eq_w[3]) begin
				real_rdata1_ex <= alu_r1_mem;
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[3])
			if(r_eq_w[2]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= alu_r1_mem;
			end // if(r_eq_w[2])
		end // if(reg_we_direct_mem==4'b0001)
		else if(reg_we_direct_mem==4'b0010) begin
			if(r_eq_w[3]) begin
				real_rdata1_ex <= hilo_mem[31:0];
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[3])
			if(r_eq_w[2]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= hilo_mem[31:0];
			end // if(r_eq_w[2])
		end // else if(reg_we_direct_mem==4'b0010)
		else if(reg_we_direct_mem==4'b0100) begin
			if(r_eq_w[3]) begin
				real_rdata1_ex <= hilo_mem[63:32];
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[3])
			if(r_eq_w[2]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= hilo_mem[63:32];
			end // if(r_eq_w[2])
		end // else if(reg_we_direct_mem==4'b0100)
		else if(reg_we_direct_mem==4'b1000) begin
			if(r_eq_w[3]) begin
				real_rdata1_ex <= cp0_data_mem;
				//real_rdata2_ex <= rdata2_ex;
			end // if(r_eq_w[3])
			if(r_eq_w[2]) begin
				//real_rdata1_ex <= rdata1_ex;
				real_rdata2_ex <= cp0_data_mem;
			end // if(r_eq_w[2])
		end // else if(reg_we_direct_mem==4'b1000)

	end // always @(*)
endmodule