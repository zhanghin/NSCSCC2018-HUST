
module conflict(
	r1_r_id,
	r2_r_id,
	r1_id,
	r2_id,
	reg_we_direct_ex,
	rw_ex,
	rw_mem,
	load_ex,
	load_mem,
	jb_id,

	conflict_stall
);
	
	input r1_r_id;
	input r2_r_id;
	input [4:0]r1_id;
	input [4:0]r2_id;
	input [3:0]reg_we_direct_ex;
	input [4:0]rw_ex;
	input [4:0]rw_mem;
	input load_ex;
	input load_mem;
	input [1:0]jb_id;
	output conflict_stall;
	wire and1;
	wire and2;
	wire and3;
	wire and4;
	wire and5;
	wire and6;

	assign and1 = r1_r_id & (r1_id==rw_ex);
	assign and2 = r2_r_id & (r2_id==rw_ex);
	assign and3 = jb_id[0] & (r1_id==rw_ex);
	assign and4 = jb_id[1] & (r2_id==rw_ex);
	assign and5 = jb_id[0] & (r1_id==rw_mem);
	assign and6 = jb_id[1] & (r2_id==rw_mem);

	assign conflict_stall = ( load_ex & (and1 | and2) & (rw_ex!=0) )
						| ( load_mem & (and5 | and6) & (rw_mem!=0) )
						| ( reg_we_direct_ex[0] & (and3 | and4) & (rw_ex!=0) );

endmodule
