/*
**	作者：张鑫
**	功能：通用寄存器的重定向
**	原创
*/
module redirect_reg_id (
	real_rdata1_id,
	real_rdata2_id,

	rdata1_id,
	rdata2_id,
	alu_r1_ex,
	alu_r1_mem,
	hilo_ex,
	hilo_mem,
	cp0_data_ex,
	cp0_data_mem,
	pc_ex,
	pc_mem,
	r1_r_id,
	r2_r_id,
	r1_id,
	r2_id,
	din_sel_ex,
	din_sel_mem,
	rw_ex,
	rw_mem
);
	input [31:0]rdata1_id;
	input [31:0]rdata2_id;
	input [31:0]alu_r1_ex;
	input [31:0]alu_r1_mem;
	input [63:0]hilo_ex;
	input [63:0]hilo_mem;
	input [31:0]cp0_data_ex;
	input [31:0]cp0_data_mem;
	input [31:0]pc_ex;
	input [31:0]pc_mem;
	input r1_r_id;
	input r2_r_id;
	input [4:0]r1_id;
	input [4:0]r2_id;
	input [2:0]din_sel_ex;
	input [2:0]din_sel_mem;
	input [4:0]rw_ex;
	input [4:0]rw_mem;

	output reg [31:0]real_rdata1_id;
	output reg [31:0]real_rdata2_id;

	wire r_eq_w[3:0];
	assign r_eq_w[3] = r1_r_id & (r1_id==rw_ex) & (rw_ex!=0);
	assign r_eq_w[2] = r2_r_id & (r2_id==rw_ex) & (rw_ex!=0);
	assign r_eq_w[1] = r1_r_id & (r1_id==rw_mem) & (rw_mem!=0);
	assign r_eq_w[0] = r2_r_id & (r2_id==rw_mem) & (rw_mem!=0);

	always @(*) begin
		real_rdata1_id <= rdata1_id;
		real_rdata2_id <= rdata2_id;
		case(din_sel_mem)
			3'b110: begin
				if(r_eq_w[1]) begin
					real_rdata1_id <= alu_r1_mem;
				end
				if(r_eq_w[0]) begin
					real_rdata2_id <= alu_r1_mem;
				end
			end
			3'b001: begin
				if(r_eq_w[1]) begin
					real_rdata1_id <= pc_mem + 8;
				end
				if(r_eq_w[0]) begin
					real_rdata2_id <= pc_mem + 8;
				end
			end
			// 3'b010: dmout
			3'b011: begin
				if(r_eq_w[1]) begin
					real_rdata1_id <= cp0_data_mem;
				end
				if(r_eq_w[0]) begin
					real_rdata2_id <= cp0_data_mem;
				end
			end
			3'b100: begin
				if(r_eq_w[1]) begin
					real_rdata1_id <= hilo_mem[63:32];
				end
				if(r_eq_w[0]) begin
					real_rdata2_id <= hilo_mem[63:32];
				end
			end
			3'b101: begin
				if(r_eq_w[1]) begin
					real_rdata1_id <= hilo_mem[31:0];
				end
				if(r_eq_w[0]) begin
					real_rdata2_id <= hilo_mem[31:0];
				end
			end
		endcase

		case(din_sel_ex)
			3'b110: begin
				if(r_eq_w[3]) begin
					real_rdata1_id <= alu_r1_ex;
				end
				if(r_eq_w[2]) begin
					real_rdata2_id <= alu_r1_ex;
				end
			end
			3'b001: begin
				if(r_eq_w[3]) begin
					real_rdata1_id <= pc_ex + 8;
				end
				if(r_eq_w[2]) begin
					real_rdata2_id <= pc_ex + 8;
				end
			end
			// 3'b010: dmout
			3'b011: begin
				if(r_eq_w[3]) begin
					real_rdata1_id <= cp0_data_ex;
				end
				if(r_eq_w[2]) begin
					real_rdata2_id <= cp0_data_ex;
				end
			end
			3'b100: begin
				if(r_eq_w[3]) begin
					real_rdata1_id <= hilo_ex[63:32];
				end
				if(r_eq_w[2]) begin
					real_rdata2_id <= hilo_ex[63:32];
				end
			end
			3'b101: begin
				if(r_eq_w[3]) begin
					real_rdata1_id <= hilo_ex[31:0];
				end
				if(r_eq_w[2]) begin
					real_rdata2_id <= hilo_ex[31:0];
				end
			end
		endcase
	end
endmodule


/*
**	作者：张鑫
**	功能：HILO寄存器的重定向
**	原创
*/
module redirect_hilo_id (
	hilo_id,
	alu_r1_ex,
	alu_r2_ex,
	alu_r1_mem,
	alu_r2_mem,
	rdata1_ex,
	rdata1_mem,
	hilo_mode_ex,
	hilo_mode_mem,

	real_hilo_id
);
	input [63:0] hilo_id;
	input [31:0] alu_r1_ex;
	input [31:0] alu_r2_ex;
	input [31:0]alu_r1_mem;
	input [31:0]alu_r2_mem;
	input [31:0]rdata1_ex;
	input [31:0]rdata1_mem;
	input [1:0]hilo_mode_ex;
	input [1:0]hilo_mode_mem;
	
	output reg[63:0] real_hilo_id;

	always @(*) begin

		real_hilo_id <= hilo_id;

		case(hilo_mode_mem)
			2'b01: begin
				real_hilo_id[31:0] <= rdata1_mem;
			end
			2'b10: begin
				real_hilo_id[63:32] <= rdata1_mem;
			end
			2'b11: begin
				real_hilo_id <= { alu_r2_mem,alu_r1_mem };
			end
		endcase

		case(hilo_mode_ex)
			2'b01: begin
				real_hilo_id[31:0] <= rdata1_ex;
			end
			2'b10: begin
				real_hilo_id[63:32] <= rdata1_ex;
			end
			2'b11: begin
				real_hilo_id <= { alu_r2_ex,alu_r1_ex };
			end
		endcase
	end
endmodule