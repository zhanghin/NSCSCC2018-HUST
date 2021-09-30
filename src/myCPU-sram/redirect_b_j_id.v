
module redirect_b_j_id (
	real_rdata1_id,
	real_rdata2_id,

	rdata1_id,
	rdata2_id,
	alu_r1_mem,
	hilo_ex,
	hilo_mem,
	cp0_data_ex,
	cp0_data_mem,
	r1_id,
	r2_id,
	bj_id,
	reg_we_direct_ex,
	reg_we_direct_mem,
	rw_ex,
	rw_mem
);
	input [31:0]rdata1_id;
	input [31:0]rdata2_id;
	input [31:0]alu_r1_mem;
	input [63:0]hilo_ex;
	input [63:0]hilo_mem;
	input [31:0]cp0_data_ex;
	input [31:0]cp0_data_mem;
	input [4:0]r1_id;
	input [4:0]r2_id;
	input [1:0]bj_id;
	input [3:0]reg_we_direct_ex;
	input [3:0]reg_we_direct_mem;
	input [4:0]rw_ex;
	input [4:0]rw_mem;
	
	output reg[31:0]real_rdata1_id;
	output reg[31:0]real_rdata2_id;

	wire [3:0]r_eq_w;
	assign r_eq_w[0] = bj_id[0] & (r1_id==rw_ex) & (rw_ex!=0);
	assign r_eq_w[1] = bj_id[1] & (r2_id==rw_ex) & (rw_ex!=0);
	assign r_eq_w[2] = bj_id[0] & (r1_id==rw_mem) & (rw_mem!=0);
	assign r_eq_w[3] = bj_id[1] & (r2_id==rw_mem) & (rw_mem!=0);

	always @(*) begin
		real_rdata1_id <= rdata1_id;
		real_rdata2_id <= rdata2_id;

		if(reg_we_direct_mem==4'b0001) begin
			if(r_eq_w[2]) begin
				real_rdata1_id <= alu_r1_mem;
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[2])
			if(r_eq_w[3]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= alu_r1_mem;
			end // else if(r_eq_w[3])
		end // if(reg_we_direct_mem==4'b0001)
		else if(reg_we_direct_mem==4'b0010) begin
			if(r_eq_w[2]) begin
				real_rdata1_id <= hilo_mem[31:0];
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[2])
			if(r_eq_w[3]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= hilo_mem[31:0];
			end // else if(r_eq_w[3])
		end // else if(reg_we_direct_mem==4'b0010)
		else if(reg_we_direct_mem==4'b0100) begin
			if(r_eq_w[2]) begin
				real_rdata1_id <= hilo_mem[63:32];
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[2])
			if(r_eq_w[3]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= hilo_mem[63:32];
			end // else if(r_eq_w[3])
		end // else if(reg_we_direct_mem==4'b0100)
		else if(reg_we_direct_mem==4'b1000) begin
			if(r_eq_w[2]) begin
				real_rdata1_id <= cp0_data_mem;
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[2])
			if(r_eq_w[3]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= cp0_data_mem;
			end // else if(r_eq_w[3])
		end // else if(reg_we_direct_mem==4'b1000)

		if(reg_we_direct_ex==4'b0010) begin
			if(r_eq_w[0]) begin
				real_rdata1_id <= hilo_ex[31:0];
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[0])
			if(r_eq_w[1]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= hilo_ex[31:0];
			end // else if(r_eq_w[1])
		end // else if(reg_we_direct_ex==4'b0010)
		else if(reg_we_direct_ex==4'b0100) begin
			if(r_eq_w[0]) begin
				real_rdata1_id <= hilo_ex[63:32];
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[0])
			if(r_eq_w[1]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= hilo_ex[63:32];
			end // else if(r_eq_w[1])
		end // else if(reg_we_direct_ex==4'b0100)
		else if(reg_we_direct_ex==4'b1000) begin
			if(r_eq_w[0]) begin
				real_rdata1_id <= cp0_data_ex;
				//real_rdata2_id <= rdata2_id;
			end // if(r_eq_w[0])
			if(r_eq_w[1]) begin
				//real_rdata1_id <= rdata1_id;
				real_rdata2_id <= cp0_data_ex;
			end // else if(r_eq_w[1])
		end // else if(reg_we_direct_ex==4'b1000)

	end // always @(*)
endmodule