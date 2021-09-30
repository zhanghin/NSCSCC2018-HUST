/*
**	作者：张鑫
**	修改：马翔、林力韬
**	功能：算术逻辑单元
**	除法以外的部分都是原创，除法参考清华大学，但有所修改
*/
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
	Result1_no_mult,
	Result2_no_mult,
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
    output [31:0] Result1;
    output [31:0] Result2;
    output reg [31:0] Result1_no_mult;
    output reg [31:0] Result2_no_mult;
    output overflow;
    output is_diving;

    assign Result1 = (S==`OP_MULT||S==`OP_MULTU) ? Result1_mult : Result1_no_mult;
    assign Result2 = (S==`OP_MULT||S==`OP_MULTU) ? Result2_mult : Result2_no_mult;

    wire [63:0] X64;
    wire [63:0] Y64;
    wire [63:0] R64_signed;
    wire [63:0] R64_unsigned;
    reg [31:0] Result1_mult;
    reg [31:0] Result2_mult;

	wire [31:0] abs_x, abs_y;
	wire [31:0] tmp_quotient, tmp_remain;
	wire [31:0] dquotient, dremain;
	wire div_unsigned;
	wire is_div;
	reg [DIV_CYCLES:0] div_stage;
	reg div_undo;
	assign div_unsigned = (S==`OP_DIVU);
	assign is_div = (S == `OP_DIV) || (S == `OP_DIVU);
	assign abs_x = (div_unsigned||!X[31]) ? X : -X;
	assign abs_y = (div_unsigned||!Y[31]) ? Y : -Y;
	assign is_diving = (is_div) & ((|div_stage) | div_undo);
	assign dquotient = (div_unsigned||!(X[31]^Y[31])) ? tmp_quotient : -tmp_quotient;
	assign dremain = (div_unsigned||!(X[31]^tmp_remain[31])) ? tmp_remain : -tmp_remain;

	always @(posedge clk) begin
	    if (!rst) begin
			div_undo<=1;
	    end
	    else if(flush) begin
			div_undo<=0;
	    end
	    else if(div_stage != 'b0 ) begin
			div_undo<=0;
	    end
		else begin
		  	div_undo<=1;
		end
	end
		
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
	    else if(is_div & div_undo) begin
	        div_stage <= 'b1 << (DIV_CYCLES-1);
	    end
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

	assign X64 = X[31] ? { 32'hffffffff,X } : { 32'h00000000,X };
	assign Y64 = Y[31] ? { 32'hffffffff,Y } : { 32'h00000000,Y };
	assign R64_signed = X64 * Y64;
	assign R64_unsigned = { 32'h00000000,X } * { 32'h00000000,Y };
	assign overflow = add_sub[0] ? ( (X[31]^Result1[31])&(Y[31]^Result1[31]) ) : 
				add_sub[1] ? ( (X[31]^Result1[31])&(!Y[31]^Result1[31]) ) : 0;
    
    always@(S,X,Y,R64_signed,R64_unsigned,dquotient,dremain) begin
	    case(S)
	        `OP_SLL: begin	//shift left logical
	            Result1_no_mult <= X<<Y[4:0];
	            Result2_no_mult <= 0;
	        end
	        `OP_SRA: begin	//shift right arithmetic
	        	if(X[31] == 1) begin
	        		Result1_no_mult <= (X >> Y[4:0]) | (32'hffffffff << (32 - Y[4:0]));
	        		Result2_no_mult <= 0;
	        	end
	        	else begin
	        		Result1_no_mult <= X >> Y[4:0];
	        		Result2_no_mult <= 0;
	        	end // else
	        end
	        `OP_SRL: begin	//shift right logical
	        	Result1_no_mult <= X >> Y[4:0];
	        	Result2_no_mult <= 0;
	        end
	        `OP_MULTU: begin	//unsigned multiply
	        	Result1_mult <= R64_unsigned[31:0];
	        	Result2_mult <= R64_unsigned[63:32];
	        end
	        `OP_DIVU: begin	//unsigned divide
	        	Result1_no_mult <= dquotient;
	        	Result2_no_mult <= dremain;
	        end
	        `OP_ADD: begin	//add
	        	Result1_no_mult <= X + Y;
	            Result2_no_mult <= 0;
	        end
	        `OP_SUB: begin	//sub
	        	Result1_no_mult <= X - Y;
	        	Result2_no_mult <= 0;
	        end
	        `OP_AND: begin	//and
	        	Result1_no_mult <= X & Y;
	        	Result2_no_mult <= 0;
	        end
	        `OP_OR: begin	//or
	        	Result1_no_mult <= X | Y;
	        	Result2_no_mult <= 0;
	        end
	        `OP_XOR: begin	//xor
	        	Result1_no_mult <= X ^ Y;
	        	Result2_no_mult <= 0;
	        end
	        `OP_NOR: begin	//nor
	        	Result1_no_mult <= ~(X | Y);
	        	Result2_no_mult <= 0;
	        end
	        `OP_SCMP: begin	//signed compare
	        	Result1_no_mult <= ( (X<Y) & !(X[31] ^ Y[31]) )
	        		| ( (X[31] ^ Y[31] ) & X[31] );
	        	Result2_no_mult <= 0;
	        end
	        `OP_UCMP: begin	//unsigned compare
	        	Result1_no_mult <= X < Y;
	        	Result2_no_mult <= 0;
	        end
	        `OP_MULT: begin	//signed multiply
	        	Result1_mult <= R64_signed[31:0];
	        	Result2_mult <= R64_signed[63:32];
	        end
	        `OP_DIV: begin	//signed divide
	        	Result1_no_mult <= dquotient;
	        	Result2_no_mult <= dremain;
	        end
	        default: begin
	        	Result1_no_mult <= 0;
	        	Result2_no_mult <= 0;
	        end
	    endcase // S
    end // always@(*)

endmodule // ALU


/*
**	作者：张鑫
**	功能：无符号除法
**	照搬清华大学的设计，原作者版权声明如下
*/

/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Non-restoring unsigned divider                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: div_uu.v,v 1.3 2003-09-17 13:08:53 rherveille Exp $
//
//  $Date: 2003-09-17 13:08:53 $
//  $Revision: 1.3 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.2  2002/10/31 13:54:58  rherveille
//               Fixed a bug in the remainder output of div_su.v
//
//               Revision 1.1.1.1  2002/10/29 20:29:10  rherveille
//
//
//
//synopsys translate_off
`timescale 1ns / 10ps
//synopsys translate_on

module div_uu(clk, ena, z, d, q, s, div0, ovf);

	parameter z_width = 16;
	parameter d_width = z_width /2;

	input clk;               // system clock
	input ena;               // clock enable

	input  [z_width -1:0] z; // divident
	input  [d_width -1:0] d; // divisor
	output [d_width -1:0] q; // quotient
	output [d_width -1:0] s; // remainder
	output div0;
	output ovf;
	reg [d_width-1:0] q;
	reg [d_width-1:0] s;
	reg div0;
	reg ovf;
	//	
	// functions
	//
	function [z_width:0] gen_s;
		input [z_width:0] si;
		input [z_width:0] di;
	begin
	  if(si[z_width])
	    gen_s = {si[z_width-1:0], 1'b0} + di;
	  else
	    gen_s = {si[z_width-1:0], 1'b0} - di;
	end
	endfunction

	function [d_width-1:0] gen_q;
		input [d_width-1:0] qi;
		input [z_width:0] si;
	begin
	  gen_q = {qi[d_width-2:0], ~si[z_width]};
	end
	endfunction

	function [d_width-1:0] assign_s;
		input [z_width:0] si;
		input [z_width:0] di;
		reg [z_width:0] tmp;
	begin
	  if(si[z_width])
	    tmp = si + di;
	  else
	    tmp = si;

	  assign_s = tmp[z_width-1:z_width-d_width];
	end
	endfunction

	//
	// variables
	//
	reg [d_width-1:0] q_pipe  [d_width-1:0];
	reg [z_width:0] s_pipe  [d_width:0];
	reg [z_width:0] d_pipe  [d_width:0];

	reg [d_width:0] div0_pipe, ovf_pipe;
	//
	// perform parameter checks
	//
	// synopsys translate_off
	initial
	begin
	  if(d_width !== z_width / 2)
	    $display("div.v parameter error (d_width != z_width/2).");
	end
	// synopsys translate_on

	integer n0, n1, n2, n3;

	// generate divisor (d) pipe
	always @(d)
	  d_pipe[0] <= {1'b0, d, {(z_width-d_width){1'b0}} };

	always @(posedge clk)
	  if(ena)begin
	    for(n0=1; n0 <= d_width; n0=n0+1)
	       d_pipe[n0] <= #1 d_pipe[n0-1];
		end

	// generate internal remainder pipe
	always @(z)
	  s_pipe[0] <= z;

	always @(posedge clk)
	  if(ena)
	    for(n1=1; n1 <= d_width; n1=n1+1)
	       s_pipe[n1] <= #1 gen_s(s_pipe[n1-1], d_pipe[n1-1]);

	// generate quotient pipe
	always @(posedge clk)
	  q_pipe[0] <= #1 0;

	always @(posedge clk)
	  if(ena)
	    for(n2=1; n2 < d_width; n2=n2+1)
	       q_pipe[n2] <= #1 gen_q(q_pipe[n2-1], s_pipe[n2]);


	// flags (divide_by_zero, overflow)
	always @(z or d)
	begin
	  ovf_pipe[0]  <= !(z[z_width-1:d_width] < d);
	  div0_pipe[0] <= ~|d;
	end

	always @(posedge clk)
	  if(ena)
	    for(n3=1; n3 <= d_width; n3=n3+1)
	    begin
	        ovf_pipe[n3] <= #1 ovf_pipe[n3-1];
	        div0_pipe[n3] <= #1 div0_pipe[n3-1];
	    end

	// assign outputs
	always @(posedge clk)
	  if(ena)
	    ovf <= #1 ovf_pipe[d_width];

	always @(posedge clk)
	  if(ena)
	    div0 <= #1 div0_pipe[d_width];

	always @(posedge clk)
	  if(ena)
	    q <= #1 gen_q(q_pipe[d_width-1], s_pipe[d_width]);

	always @(posedge clk)
	  if(ena)
	    s <= #1 assign_s(s_pipe[d_width], d_pipe[d_width]);

	// always@(posedge clk)begin
	// 	if()
	// 	if(div_undo == 0)	div_undo<=1;
	// end
endmodule