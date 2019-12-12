
//unsimulated
`define OP_SLL 0
`define OP_SRA 1
`define OP_SRL 2
`define OP_MULTU 3
`define OP_DIVU 4
`define OP_ADD 5
`define OP_SUB 6
`define OP_AND 7
`define OP_OR 8
`define OP_XOR 9
`define OP_NOR 10
`define OP_SCMP 11
`define OP_UCMP 12
`define OP_MULT 13
`define OP_DIV 14

module ALU(
	X,
	Y,
	S,
	add_sub,
	clk,
	rst,
	flush,

	Result1,
	Result2,
	overflow,
	is_diving
    );
	parameter DIV_CYCLES = 32;
    input [31:0] X;
    input [31:0] Y;
    input [3:0] S;
    input [1:0]add_sub;
    input clk;
    input rst;
    input flush;
    output reg [31:0] Result1;
    output reg [31:0] Result2;
    output overflow;
    output is_diving;
    wire OF;
    wire UOF;
    wire Equal;
    wire [63:0] X64;
    wire [63:0] Y64;
    wire [63:0] R64_signed;
    wire [63:0] R64_unsigned;

	wire [31:0] abs_x, abs_y;
	wire [31:0] tmp_quotient, tmp_remain;
	wire [31:0] dquotient, dremain;
	wire div_unsigned;
	wire is_div;
	reg [DIV_CYCLES:0] div_stage;

	assign div_unsigned = (S==`OP_DIVU);
	assign is_div = (S == `OP_DIV) || (S == `OP_DIVU);
	assign abs_x = (div_unsigned||!X[31]) ? X : -X;
	assign abs_y = (div_unsigned||!Y[31]) ? Y : -Y;
	assign is_diving = is_div & (|div_stage);
	assign dquotient = (div_unsigned||!(X[31]^Y[31])) ? tmp_quotient : -tmp_quotient;
	assign dremain = (div_unsigned||!(X[31]^tmp_remain[31])) ? tmp_remain : -tmp_remain;

	always @(posedge clk) begin
	    if (!rst) begin
	        div_stage <= 'b0;
	    end
	    else if(flush) begin
	        div_stage <= 'b0;
	    end
	    else if(div_stage != 'b0 ) begin
	        div_stage <= div_stage >> 1; 
	    end
	    // else if(op == `OP_MUL /*|| op == `OP_MULT */|| op == `OP_MSUB || op == `OP_MADD) begin
	    //     div_stage <= 2'b10;
	    // end
	    else if(is_div) begin
	        div_stage <= 'b1 << (DIV_CYCLES-1);
	    end
	    $display("op=%h,X=%8h,Y=%8h,dquotient=%8h,dremain=%8h,div_stage=%10h,is_diving=%h"
	    	,S,X,Y,dquotient,dremain,div_stage,is_diving);
	end

	div_uu #(.z_width(64)) div_uu0(
	    .clk (clk),
	    .ena (is_div),
	    .z   ({32'h0,abs_x}),
	    .d   (abs_y),
	    .q   (tmp_quotient),
	    .s   (tmp_remain),
	    .div0(),
	    .ovf ()
	);

    //assign Equal = !(X ^ Y);
	assign X64 = X[31] ? { 32'hffffffff,X } : { 32'h00000000,X };
	assign Y64 = Y[31] ? { 32'hffffffff,Y } : { 32'h00000000,Y };
	assign R64_signed = X64 * Y64;
	assign R64_unsigned = { 32'h00000000,X } * { 32'h00000000,Y };
	//assign OF = ( X[31] ^ Result1[31] ) & ( Y[31] ^ Result1[31] );
	//assign UOF = Result1<X||Result1<Y;
	assign overflow = add_sub[0] ? ( (X[31]^Result1[31])&(Y[31]^Result1[31]) ) : 
				add_sub[1] ? ( (X[31]^Result1[31])&(!Y[31]^Result1[31]) ) : 0;
    
    always@(S,X,Y,R64_signed,R64_unsigned,dquotient,dremain) begin
	    case(S)
	        `OP_SLL: begin	//shift left logical
	            Result1 <= X<<Y[4:0];
	            Result2 <= 0;
	        end
	        `OP_SRA: begin	//shift right arithmetic
	        	if(X[31] == 1) begin
	        		Result1 <= (X >> Y[4:0]) | (32'hffffffff << (32 - Y[4:0]));
	        		Result2 <= 0;
	        	end
	        	else begin
	        		Result1 <= X >> Y[4:0];
	        		Result2 <= 0;
	        	end // else
	        end
	        `OP_SRL: begin	//shift right logical
	        	Result1 <= X >> Y[4:0];
	        	Result2 <= 0;
	        end
	        `OP_MULTU: begin	//unsigned multiply
	        	Result1 <= R64_unsigned[31:0];
	        	Result2 <= R64_unsigned[63:32];
	        end
	        `OP_DIVU: begin	//unsigned divide
/*	        	Result1 <= X / Y;
	        	Result2 <= X % Y;*/
	        	Result1 <= dquotient;
	        	Result2 <= dremain;
	        end
	        `OP_ADD: begin	//add
	        	Result1 <= X + Y;
	            Result2 <= 0;
	        end
	        `OP_SUB: begin	//sub
	        	Result1 <= X - Y;
	        	Result2 <= 0;
	        end
	        `OP_AND: begin	//and
	        	Result1 <= X & Y;
	        	Result2 <= 0;
	        end
	        `OP_OR: begin	//or
	        	Result1 <= X | Y;
	        	Result2 <= 0;
	        end
	        `OP_XOR: begin	//xor
	        	Result1 <= X ^ Y;
	        	Result2 <= 0;
	        end
	        `OP_NOR: begin	//nor
	        	Result1 <= ~(X | Y);
	        	Result2 <= 0;
	        end
	        `OP_SCMP: begin	//signed compare
	        	Result1 <= ( (X<Y) & !(X[31] ^ Y[31]) )
	        		| ( (X[31] ^ Y[31] ) & X[31] );
	        	Result2 <= 0;
	        end
	        `OP_UCMP: begin	//unsigned compare
	        	Result1 <= X < Y;
	        	Result2 <= 0;
	        end
	        `OP_MULT: begin	//signed multiply
	        	Result1 <= R64_signed[31:0];
	        	Result2 <= R64_signed[63:32];
	        end
	        `OP_DIV: begin	//signed divide
	        	//unfinished
/*	        	Result1 <= $signed(X64) / $signed(Y64);
	        	Result2 <= $signed(X64) % $signed(Y64);*/
	        	Result1 <= dquotient;
	        	Result2 <= dremain;
	        end
	        default: begin
	        	Result1 <= 0;
	        	Result2 <= 0;
	        end
	    endcase // S
    end // always@(*)

endmodule // ALU