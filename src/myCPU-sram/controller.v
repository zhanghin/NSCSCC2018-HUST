//control_bus位数有冗余，最终版本需要去掉，流水段中的位数同样需要修改
module controller(
//input
	op,
	func,
	rs,
	rt,
//output
	control_bus,
	branch_jump,
	in_delayslot
);
	input [5:0]op;
	input [5:0]func;
	input [4:0]rs;
	input [4:0]rt;

	output [60:0]control_bus;
//所有跳转指令编码，送跳转逻辑
	output [9:0]branch_jump;
//延迟槽，送IF-ID流水段，延迟一个周期
	output in_delayslot;
//ALU操作码
	wire [3:0]aluop;
//寄存器文件读编号选择
	wire r1_sel;
	wire r2_sel;
//寄存器写使能
	wire regs_we;
//寄存器写编号选择
	wire [1:0]rw_sel;
//寄存器写数据选择
	wire [2:0]din_sel;
//cp0寄存器写使能
	wire cp0_we;
//立即数扩展选择
	wire [1:0]ext_sel;
//ALU操作数选择
	wire [1:0]alua_sel;
	wire [1:0]alub_sel;
//读寄存器第1路、2路，用于重定向
	wire r1_r;
	wire r2_r;
//lb、lbu、lh、lhu、lw
	wire load;
//sb、sh、sw,多余
	wire dm_we;
//hilo寄存器的写模式，高低位分别对应hi和lo
	wire [1:0]hilo_mode;
//非法指令
	wire invalid_inst;
//有符号加减法，用于alu的溢出判断
	wire [1:0]add_sub;
//低位是跳转指令中读第1路寄存器的指令
//高位是跳转指令中读第2路寄存器的指令
//用于跳转指令的重定向
	wire [1:0]bj_reg;
//用于重定向的写寄存器使能信号
//0位是普通指令、1位是mflo
//2位是mfhi、3位是mfc0
	wire [3:0]reg_we_direct;
//所有仿存指令统一编码
//000 lb、001 lbu、010 lh、011 lhu、100 lw、101 sb、110 sh、111 sw
	wire [2:0]load_store;

	wire op6,op5,op4,op3,op2,op1;
	wire f6,f5,f4,f3,f2,f1;
	wire rs5,rs4,rs3,rs2,rs1;
	wire rt5,rt4,rt3,rt2,rt1;

	wire r;
	wire add;
	wire addi;
	wire addu;
	wire addiu;
	wire sub;
	wire subu;
	wire slt;
	wire slti;
	wire sltu;
	wire sltiu;
	wire div;
	wire divu;
	wire mult;
	wire multu;
	wire and_;
	wire andi;
	wire lui;
	wire nor_;
	wire or_;
	wire ori;
	wire xor_;
	wire xori;
	wire sll;
	wire sllv;
	wire sra;
	wire srav;
	wire srl;
	wire srlv;
	wire beq;
	wire bne;
	wire bgez;
	wire bgtz;
	wire blez;
	wire bltz;
	wire bltzal;
	wire bgezal;
	wire j;
	wire jal;
	wire jr;
	wire jalr;
	wire mfhi;
	wire mflo;
	wire mthi;
	wire mtlo;
	wire break_;
	wire syscall;
	wire eret;
	wire mfc0;
	wire mtc0;
	wire lb;
	wire lbu;
	wire lh;
	wire lhu;
	wire lw;
	wire sb;
	wire sh;
	wire sw;

	assign aluop[3] = or_ | ori | xor_ | xori | nor_ | slt | slti 
			| sltu | sltiu | mult | div; 
	assign aluop[2] = add | addi | addu | addiu | lb | lbu | lh | lhu
			| lw | sb | sh | sw | sub | subu | and_ | andi | sltu | sltiu
			| divu | mult | div;
	assign aluop[1] = srl | srlv | sub | subu | and_ | andi | nor_
			| slt | slti | multu | div;
	assign aluop[0] = sra | srav | add | addi | addu | addiu | lb | lbu
			| lh | lhu | lw | sb | sh | sw | and_ | andi | xor_ | xori
			| slt | slti | multu | mult;

	assign r1_sel = sllv | srav | srlv;
	assign r2_sel = add | addu | sub | subu | slt | sltu | div | divu | mult
			| multu | and_ | nor_ | or_ | xor_ | sll | sra | srl | beq | bne
			| bgtz | blez | mtc0 | sb | sh | sw;

	assign regs_we = add | addi | addu | addiu | sub | subu | slt | slti | sltu | sltiu
			| and_ | andi | lui | nor_ | or_ | ori | xor_ | xori | sll | sllv | sra | srav
			| srl | srlv | bltzal | bgezal | jal | jalr | mfhi | mflo | mfc0 |
			lb | lbu | lh | lhu | lw ;

	assign rw_sel[1] = add | addu | sub | subu | slt | sltu | and_ | nor_ | or_ | xor_
			| sll | sllv | sra | srav | srl | srlv | jalr | mfhi | mflo;
	assign rw_sel[0] = addi | addiu | slti | sltiu | andi | lui | ori | xori | mfc0 | lb
			| lbu | lh | lhu | lw;

	assign din_sel[2] = mfhi | mflo;
	assign din_sel[1] = mfc0 | lb | lbu | lh | lhu | lw;
	assign din_sel[0] = bltzal | bgezal | jal | jalr | mflo | mfc0;

	assign cp0_we = mtc0;

	assign ext_sel[1] = sll | sra | srl;
	assign ext_sel[0] = andi | lui | ori | xori;

	assign alua_sel[1] = lui;
	assign alua_sel[0] = sll | sra | srl;

	assign alub_sel[1] = lui | bgez | bltz | bltzal | bgezal;
	assign alub_sel[0] = addi | addiu | slti | sltiu | andi | lui
			| ori | xori | sll | sra | srl | lb | lbu | lh | lhu 
			| lw | sb | sh | sw;

	assign r1_r = add | addi | addu | addiu | sub | subu | slt | slti | sltu | sltiu
			| div | divu | mult | multu | and_ | andi | nor_ | or_ | ori | xor_ | xori
			| sllv | srav | srlv | beq | bne | bgez | bgtz | blez | bltz | bltzal
			| bgezal | jr | jalr | lb | lbu | lh | lhu | lw | sb | sh | sw | mthi | mtlo;
	assign r2_r = add | addu | sub | subu | slt | sltu | div | divu | mult | multu
			| and_ | nor_ | or_ | xor_ | sll | sllv | sra | srav | srl | srlv | beq
			| bne | bgtz | blez | eret | mtc0 | sb | sh | sw;

	assign load = lb | lbu | lh | lhu | lw;

	assign branch_jump = { jalr|jr,jal|j,bgezal,bltzal,bltz,blez,bgtz,bgez,bne,beq };

	assign dm_we = sb | sh | sw;

	assign load_store[0] = lbu | lhu | sb | sw;
	assign load_store[1] = lh | lhu | sh | sw;
	assign load_store[2] = lw | sb | sh | sw;

	assign reg_we_direct[0] = add | addi | addu | addiu | sub | subu | slt | slti | sltu | sltiu
			| and_ | andi | lui | nor_ | or_ | ori | xor_ | xori | sll | sllv | sra | srav
			| srl | srlv | bltzal | bgezal | jal | jalr | eret | lb | lbu | lh | lhu | lw ;
	assign reg_we_direct[1] = mflo;
	assign reg_we_direct[2] = mfhi;
	assign reg_we_direct[3] = mfc0;

	assign bj_reg[1] = beq | bne | bgtz | blez;	//读r2寄存器
	assign bj_reg[0] = beq | bne | bgez | bgtz | blez | bltz | bltzal | bgezal | jr | jalr;	//读r1寄存器

	assign add_sub[0] = add | addi;
	assign add_sub[1] = sub;

	assign in_delayslot = beq | bne | bgez | bgtz | blez | bltz | bltzal | bgezal 
			| j | jal | jr | jalr;

	assign hilo_mode[1] = div | divu | mult | multu | mthi;
	assign hilo_mode[0] = div | divu | mult | multu | mtlo;
	
	assign control_bus = { 
			add_sub[1:0],load_store[2:0], reg_we_direct[3:0], bj_reg[1:0], 1'b0, invalid_inst,
			eret, break_, syscall, hilo_mode[1:0], dm_we, load, r2_r, r1_r,
			alub_sel[1:0], alua_sel[1:0], ext_sel[1:0], cp0_we,
			din_sel[2:0], rw_sel[1:0], regs_we, r2_sel, r1_sel, aluop[3:0] };

	assign invalid_inst = ~(add | addi | addu | addiu | sub | subu | slt | slti | sltu | sltiu
		| div | divu | mult | multu	| and_ | andi | lui | nor_ | or_ | ori | xor_ | xori | sll
		| sllv | sra | srav | srl | srlv | beq | bne | bgez | bgtz | blez | bltz | bltzal | bgezal
		| j | jal | jr | jalr | mfhi | mflo | mthi | mtlo | break_ | syscall | eret | mfc0
		| mtc0 | lb | lbu | lh | lhu | lw | sb | sh | sw);

	assign {op6,op5,op4,op3,op2,op1} = op;
	assign {f6,f5,f4,f3,f2,f1} = func;
	assign {rs5,rs4,rs3,rs2,rs1} = rs;
	assign {rt5,rt4,rt3,rt2,rt1} = rt;

	assign addi = ~op6 & ~op5 & op4 & ~op3 & ~op2 & ~op1;	//addi op = 001000
	assign addiu = ~op6 & ~op5 &  op4 & ~op3 & ~op2 & op1;	//addiu op = 001001
	assign slti = ~op6 & ~op5 & op4 & ~op3 & op2 & ~op1;	//slti op = 001010
	assign sltiu = ~op6 & ~op5 & op4 & ~op3 & op2 & op1;	//sltiu op = 001011
	assign andi = ~op6 & ~op5 & op4 & op3 & ~op2 & ~op1;	//andi op = 001100
	assign lui = ~op6 & ~op5 & op4 & op3 & op2 & op1;		//lui op = 001111
	assign ori = ~op6 & ~op5 & op4 & op3 & ~op2 & op1;		//ori op = 001101
	assign xori = ~op6 & ~op5 & op4 & op3 & op2 & ~op1;		//xori op = 001110
	assign beq = ~op6 & ~op5 & ~op4 & op3 & ~op2 & ~op1;	//beq op = 000100
	assign bne = ~op6 & ~op5 & ~op4 & op3 & ~op2 & op1;		//bne op = 000101
	assign bgtz = ~op6 & ~op5 & ~op4 & op3 & op2 & op1;		//bgtz op = 000111
	assign blez = ~op6 & ~op5 & ~op4 & op3 & op2 & ~op1;	//blez op = 000110
	assign j = ~op6 & ~op5 & ~op4 & ~op3 & op2 & ~op1;		//j op = 000010
	assign jal = ~op6 & ~op5 & ~op4 & ~op3 & op2 & op1;		//jal op = 000011
	assign lb = op6 & ~op5 & ~op4 & ~op3 & ~op2 & ~op1;		//lb op = 100000
	assign lbu = op6 & ~op5 & ~op4 & op3 & ~op2 & ~op1;		//lbu op = 100100
	assign lh = op6 & ~op5 & ~op4 & ~op3 & ~op2 & op1;		//lh op = 100001
	assign lhu = op6 & ~op5 & ~op4 & op3 & ~op2 & op1;		//lhu op = 100101
	assign lw = op6 & ~op5 & ~op4 & ~op3 & op2 & op1;		//lw op = 100011
	assign sb = op6 & ~op5 & op4 & ~op3 & ~op2 & ~op1;		//sb op = 101000
	assign sh = op6 & ~op5 & op4 & ~op3 & ~op2 & op1;		//sh op = 101001
	assign sw = op6 & ~op5 & op4 & ~op3 & op2 & op1;		//sw op = 101011

	assign r = ~(op1|op2|op3|op4|op5|op6);	//op=000000, r instruction

	assign add = r & f6 & ~f5 & ~f4 & ~f3 & ~f2 & ~f1;		//add func = 100000
	assign addu = r & f6 & ~f5 & ~f4 & ~f3 & ~f2 & f1;		//addu func = 100001
	assign sub = r & f6 & ~f5 & ~f4 & ~f3 & f2 & ~f1;		//sub func = 100010
	assign subu = r & f6 & ~f5 & ~f4 & ~f3 & f2 & f1;		//subu func = 100011
	assign slt = r & f6 & ~f5 & f4 & ~f3 & f2 & ~f1;		//slt func = 101010
	assign sltu = r & f6 & ~f5 & f4 & ~f3 & f2 & f1;		//sltu func = 101011
	assign div = r & ~f6 & f5 & f4 & ~f3 & f2 & ~f1;		//div func = 011010
	assign divu = r & ~f6 & f5 & f4 & ~f3 & f2 & f1;		//divu func = 011011
	assign mult = r & ~f6 & f5 & f4 & ~f3 & ~f2 & ~f1;		//mult func = 011000
	assign multu = r & ~f6 & f5 & f4 & ~f3 & ~f2 & f1;		//multu func = 011001
	assign and_ = r & f6 & ~f5 & ~f4 & f3 & ~f2 & ~f1;		//and func = 100100
	assign nor_ = r & f6 & ~f5 & ~f4 & f3 & f2 & f1;		//nor func = 100111
	assign or_ = r & f6 & ~f5 & ~f4 & f3 & ~f2 & f1;		//or func = 100101
	assign xor_ = r & f6 & ~f5 & ~f4 & f3 & f2 & ~f1;		//xor func = 100110
	assign sll = r & ~f6 & ~f5 & ~f4 & ~f3 & ~f2 & ~f1;		//sll func = 000000
	assign sllv = r & ~f6 & ~f5 & ~f4 & f3 & ~f2 & ~f1;		//sllv func = 000100
	assign sra = r & ~f6 & ~f5 & ~f4 & ~f3 & f2 & f1;		//sra func = 000011
	assign srav = r & ~f6 & ~f5 & ~f4 & f3 & f2 & f1;		//srav func = 000111
	assign srl = r & ~f6 & ~f5 & ~f4 & ~f3 & f2 & ~f1;		//srl func = 000010
	assign srlv = r & ~f6 & ~f5 & ~f4 & f3 & f2 & ~f1;		//srlv func = 000110
	assign jr = r & ~f6 & ~f5 & f4 & ~f3 & ~f2 & ~f1;		//jr func = 001000
	assign jalr = r & ~f6 & ~f5 & f4 & ~f3 & ~f2 & f1;		//jalr func = 001001
	assign mfhi = r & ~f6 & f5 & ~f4 & ~f3 & ~f2 & ~f1;		//mfhi func = 010000
	assign mflo = r & ~f6 & f5 & ~f4 & ~f3 & f2 & ~f1;		//mflo func = 010010
	assign mthi = r & ~f6 & f5 & ~f4 & ~f3 & ~f2 & f1;		//mthi func = 010001
	assign mtlo = r & ~f6 & f5 & ~f4 & ~f3 & f2 & f1;		//mtlo func = 010011
	assign break_ = r & ~f6 & ~f5 & f4 & f3 & ~f2 & f1;		//break func = 001101
	assign syscall = r & ~f6 & ~f5 & f4 & f3 & ~f2 & ~f1;	//syscall func = 001100

	assign eret = ~op6 & op5 & ~op4 & ~op3 & ~op2 & ~op1
			& ~f6 & f5 & f4 & ~f3 & ~f2 & ~f1;		//eret op = 010000,func = 011000

	assign bgez = ~op6 & ~op5 & ~op4 & ~op3 & ~op2 & op1 
			& ~rt5 & ~rt4 & ~rt3 & ~rt2 & rt1;		//bgez op = 000001,rt = 00001
	assign bltz = ~op6 & ~op5 & ~op4 & ~op3 & ~op2 & op1 
			& ~rt5 & ~rt4 & ~rt3 & ~rt2 & ~rt1;		//bltz op = 000001,rt = 00000
	assign bltzal = ~op6 & ~op5 & ~op4 & ~op3 & ~op2 & op1 
			& rt5 & ~rt4 & ~rt3 & ~rt2 & ~rt1;		//bltzal op = 000001,rt = 10000
	assign bgezal = ~op6 & ~op5 & ~op4 & ~op3 & ~op2 & op1 
			& rt5 & ~rt4 & ~rt3 & ~rt2 & rt1;		//bgezal op = 000001,rt = 10001

	assign mfc0 = ~op6 & op5 & ~op4 & ~op3 & ~op2 & ~op1 
			& ~rs5 & ~rs4 & ~rs3 & ~rs2 & ~rs1;		//mfc0 op = 010000,rs = 00000
	assign mtc0 = ~op6 & op5 & ~op4 & ~op3 & ~op2 & ~op1 
			& ~rs5 & ~rs4 & rs3 & ~rs2 & ~rs1;		//mtc0 op = 010000,rs = 00100
endmodule