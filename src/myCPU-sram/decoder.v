
//simulated

module decoder(
	instruction,
    
	rs,
	rt,
	rd,
	op,
	func,
	imm16,
	imm26,
	shamt,
	sel
    );

    input [31:0]instruction;

    output [5:0] op,func;
    output [4:0] rs,rt,rd;
    output [15:0] imm16;
    output [25:0] imm26;
    output [2:0] sel;
    output [4:0] shamt;

    assign op = instruction[31:26];
    assign rs = instruction[25:21];
    assign rt = instruction[20:16];
    assign rd = instruction[15:11];
    assign shamt = instruction[10:6];
    assign func = instruction[5:0];
    assign imm16 = instruction[15:0];
    assign imm26 = instruction[25:0];
    assign sel = instruction[2:0];
endmodule
