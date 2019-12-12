
module debug(
	pc_if,
	pc_id,
	pc_ex,
	pc_mem,
	pc_wb,
	instruction_if,
	instruction_id,
	rs_id,
	rt_id,
	rd_id,
	r1_sel_id,
	r2_sel_id,
	r1_id,
	r2_id,
	rw_id,
	rw_ex,
	rw_mem,
	rw_wb,
	reg_din_wb,
	alu_r1_mem,
	alu_r1_wb,
	reg_we_id,
	reg_we_ex,
	reg_we_mem,
	reg_we_wb,
	stall_pc,
	stall_ifid,
	stall_idex,
	stall_exmem,
	stall_memwb,
	is_exception,
	dm_we_mem,
	dm_we_wb,
	Dmout_mem,
	Dmout_wb,
	din_sel_wb,
	mode_mem,
	rdata1_id,
	rdata2_id,
	real_rdata1_id,
	real_rdata2_id,
	hilo_id,
	hilo_ex,
	real_hilo_ex,
	hilo_mem,
	hilo_wb,
	rdata1_ex,
	rdata2_ex,
	rdata2_mem,
	rdata2_wb,
	alua_sel_ex,
	alub_sel_ex,
	extern_ex,
	alu_a,
	alu_b,
	debug_en,
	is_bj_id,
	bj_id,
	imm26_id,
	imm32_id,
	bj_addr_id,
	cp0_data_id,
	cp0_data_ex,
	cp0_data_mem,
	cp0_data_wb,
	sel_id,
	rd_wb,
	sel_wb,
	cp0_we_wb,
	epc_id,
	exp_epc_mem,
	clk
	);
	input [4:0]rd_wb;
	input [2:0]sel_id,sel_wb;
	input cp0_we_wb;
	input [31:0]epc_id,exp_epc_mem;
	input [31:0]cp0_data_id,cp0_data_ex,cp0_data_mem,cp0_data_wb;
	input [63:0]hilo_id,hilo_ex,real_hilo_ex,hilo_mem,hilo_wb;
	input [31:0]rdata1_id,rdata2_id;
	input [9:0]bj_id;
	input [25:0]imm26_id;
	input [31:0]imm32_id,bj_addr_id;
	input debug_en,is_bj_id;
	input [1:0]alua_sel_ex;
	input [1:0]alub_sel_ex;
	input [31:0]extern_ex;
	input [31:0]alu_a;
	input [31:0]alu_b;
	input [3:0]mode_mem;
	input [2:0]din_sel_wb;
	input [31:0]Dmout_mem,Dmout_wb;
	input r1_sel_id,r2_sel_id;
	input [31:0]real_rdata1_id,real_rdata2_id,rdata1_ex,rdata2_ex,alu_r1_mem,alu_r1_wb,rdata2_mem;
	input [31:0]rdata2_wb;
	input clk;
	input is_exception,dm_we_mem,dm_we_wb;
	input reg_we_id,reg_we_ex,reg_we_mem,reg_we_wb;
	input stall_pc,stall_ifid,stall_idex,stall_exmem,stall_exmem,stall_memwb;
	input [31:0]pc_if,pc_id,pc_ex,pc_mem,pc_wb,reg_din_wb;
	input [31:0]instruction_if,instruction_id;
	input [4:0]rs_id,rt_id,rd_id,r1_id,r2_id,rw_id,rw_ex,rw_mem,rw_wb;
	always @(posedge clk) begin
		$display("------------------------------------------------------------",);
		$display("pc_if = %8h,pc_id = %8h,pc_ex = %8h,pc_mem = %8h,pc_wb = %8h",
			pc_if,pc_id,pc_ex,pc_mem,pc_wb);
		$display("inst_if = %8h,inst_id = %8h,debug_en=%h,is_bj_id = %h,bj_id=%3h,imm26_id=%7h,imm32_id=%8h,bj_addr_id=%8h"
			,instruction_if,instruction_id,debug_en,is_bj_id,bj_id,imm26_id,imm32_id,bj_addr_id);
			// $display("cp0_data_id=%8h,cp0_data_ex=%8h,cp0_data_mem=%8h,cp0_data_wb=%8h"
			// 	,cp0_data_id,cp0_data_ex,cp0_data_mem,cp0_data_wb);
			$display("rd_id=%2h,sel_id=%h,rd_wb=%2h,sel_wb=%h,cp0_we_wb=%h,epc_id=%8h,exp_epc_mem=%8h"
				,rd_id,sel_id,rd_wb,sel_wb,cp0_we_wb,epc_id,exp_epc_mem);
			$display("stall_pc = %1h,stall_ifid = %1h,stall_idex = %1h,stall_exmem = %1h,stall_memwb = %1h"
				,stall_pc,stall_ifid,stall_idex,stall_exmem,stall_memwb);
			$display("hilo_id=%16h,hilo_ex=%16h,real_hilo_ex=%16h,hilo_mem=%16h,hilo_wb=%16h"
				,hilo_id,hilo_ex,real_hilo_ex,hilo_mem,hilo_wb);
			$display("is_exp = %1h,dm_we_mem = %1h,dm_we_wb = %1h",
				is_exception,dm_we_mem,dm_we_wb);
			$display("rs_id = %2h,rt_id = %2h,rd_id = %2h",rs_id,rt_id,rd_id);
			$display("r1_sel_id = %h,r2_sel_id = %h,r1_id = %2h,r2_id = %2h,rw_id = %2h,rw_ex = %2h,rw_mem = %2h,rw_wb = %2h"
				,r1_sel_id,r2_sel_id,r1_id,r2_id,rw_id,rw_ex,rw_mem,rw_wb);
			$display("reg_we_id = %1h,reg_we_ex = %1h,reg_we_mem = %1h,reg_we_wb = %1h,reg_din_wb = %8h"
				,reg_we_id,reg_we_ex,reg_we_mem,reg_we_wb,reg_din_wb);
			$display("rdata1_id=%8h,rdata2_id=%8h"
				,rdata1_id,rdata2_id);
			$display("real_rdata1_id = %8h,real_rdata2_id = %8h,rdata1_ex = %8h,rdata2_ex = %8h,rdata2_mem = %8h,alu_r1_mem = %8h"
				,real_rdata1_id,real_rdata2_id,rdata1_ex,rdata2_ex,rdata2_mem,alu_r1_mem);
			$display("rdata2_wb=%8h"
				,rdata2_wb,);
			$display("alu_r1_wb = %8h,Dmout_mem = %8h,Dmout_wb = %8h,din_sel_wb = %h,mode_mem = %h"
				,alu_r1_wb,Dmout_mem,Dmout_wb,din_sel_wb,mode_mem);
			$display("alua_sel_ex=%h,alub_sel_ex=%h,extern_ex=%8h,alu_a=%8h,alu_b=%8h"
				,alua_sel_ex,alub_sel_ex,extern_ex,alu_a,alu_b);
	end

endmodule
