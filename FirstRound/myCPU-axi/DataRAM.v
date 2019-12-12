/*
**	作者：张鑫
**	功能：对数据RAM读出的数据进行字节选择
**	原创
*/
module DMout_select_extend (
	load_store_wb,
	DMout_wb,
	data_sram_addr_byte_wb,

	real_DMout_wb
);
	input [2:0]load_store_wb;
	input [31:0]DMout_wb;
	input [1:0]data_sram_addr_byte_wb;
	output reg [31:0]real_DMout_wb;
	
	reg[7:0]byte_;
	reg[15:0]half;

	always @(*) begin
		case(data_sram_addr_byte_wb)
			2'b00: begin
				byte_ <= DMout_wb[7:0];
				half <= DMout_wb[15:0];
			end // 2'b00:
			2'b01: begin
				byte_ <= DMout_wb[15:8];
				half <= DMout_wb[15:0];
			end // 2'b01:
			2'b10: begin
				byte_ <= DMout_wb[23:16];
				half <= DMout_wb[31:16];
			end // 2'b10:
			2'b11: begin
				byte_ <= DMout_wb[31:24];
				half <= DMout_wb[31:16];
			end // 2'b11:
		endcase
	end // always @(*)

	always @(*) begin
		case(load_store_wb)
			3'b000: begin	//lb
				real_DMout_wb <= byte_[7] ? {24'hffffff,byte_} : {24'h000000,byte_};
			end // 3'b000:
			3'b001:	begin	//lbu
				real_DMout_wb <= {24'h000000,byte_};
			end // 3'b001:
			3'b010:	begin	//lh
				real_DMout_wb <= half[15] ? {16'hffff,half} : {16'h0000,half};
			end // 3'b010:
			3'b011: begin	//lhu
				real_DMout_wb <= {16'h0000,half};
			end // 3'b011:
			3'b100: begin	//lw
				real_DMout_wb <= DMout_wb;
			end // 3'b100:
		endcase
	end // always @(*)
endmodule


/*
**	作者：张鑫
**	功能：对数据RAM的写入数据进行移位
**	原创
*/
module dm_in_select (
	rdata2_mem,
	load_store_mem,
	data_sram_addr_byte_mem,
	
	dram_wdata_mem
);
	input [31:0]rdata2_mem;
	input [2:0]load_store_mem;
	input [1:0]data_sram_addr_byte_mem;
	output reg[31:0]dram_wdata_mem;

	always @(*) begin
		case(load_store_mem)
			3'b101: begin	//sb
				case(data_sram_addr_byte_mem)
					2'b00: begin
						dram_wdata_mem <= rdata2_mem;
					end // 2'b00:
					2'b01: begin
						dram_wdata_mem <= { rdata2_mem[23:0],8'h00 };
					end // 2'b01:
					2'b10: begin
						dram_wdata_mem <= { rdata2_mem[15:0],16'h0000 };
					end // 2'b10:
					2'b11: begin
						dram_wdata_mem <= { rdata2_mem[7:0],24'h000000 };
					end // 2'b11:
					default: begin
						dram_wdata_mem <= rdata2_mem;
					end // default:
				endcase
			end // 3'b101:
			3'b110: begin	//sh
				case(data_sram_addr_byte_mem)
					2'b00: begin
						dram_wdata_mem <= rdata2_mem;
					end // 2'b00:
					2'b01: begin
						dram_wdata_mem <= { rdata2_mem[23:0],8'h00 };
					end // 2'b01:
					2'b10: begin
						dram_wdata_mem <= { rdata2_mem[15:0],16'h0000 };
					end // 2'b10:
					2'b11: begin
						dram_wdata_mem <= { rdata2_mem[7:0],24'h000000 };
					end // 2'b11:
					default: begin
						dram_wdata_mem <= rdata2_mem;
					end // default:
				endcase
			end // 3'b110:
			3'b111: begin	//sw
				dram_wdata_mem <= rdata2_mem;
			end // 3'b111:
			default: begin
				dram_wdata_mem <= rdata2_mem;
			end // default:
		endcase // load_store_mem
	end // always @(*)
endmodule


/*
**	作者：张鑫
**	功能：生成数据RAM的4位使能信号
**	原创
*/
module dram_mode (
	load_store_mem,
	data_sram_addr_byte_mem,

	mode_mem
);
	input [2:0]load_store_mem;
	input [1:0]data_sram_addr_byte_mem;
	output reg[3:0]mode_mem;

	always @(load_store_mem,data_sram_addr_byte_mem) begin
		case(load_store_mem)
			3'b101: begin	//sb
				case(data_sram_addr_byte_mem)
					2'b00: begin
						mode_mem <= 4'b0001;
					end // 2'b00:
					2'b01: begin
						mode_mem <= 4'b0010;
					end // 2'b01:
					2'b10: begin
						mode_mem <= 4'b0100;
					end // 2'b10:
					2'b11: begin
						mode_mem <= 4'b1000;
					end // 2'b11:
					default :begin
						mode_mem <= 4'b0000;
					end // default :
				endcase
			end // 3'b101:
			3'b110: begin	//sh
				case(data_sram_addr_byte_mem)
					2'b00: begin
						mode_mem <= 4'b0011;
					end
					2'b01: begin
						mode_mem <= 4'b0110;
					end // 2'b01:
					2'b10: begin
						mode_mem <= 4'b1100;
					end // 2'b10:
					2'b11: begin
						mode_mem <= 4'b1000;
					end // 2'b11:
					default :begin
						mode_mem <= 4'b0000;
					end // default :
				endcase
			end // 3'b110:
			3'b111:	begin	//sw
				mode_mem <= 4'b1111;
			end // 3'b111:
			default: begin
				mode_mem <= 4'b0000;
			end
		endcase // load_store_mem
	end // always @(*)
endmodule

/*
**	作者：张鑫
**	功能：数据RAM地址异常检测
**	原创
*/
module illegal_addr (
	load_store_mem,
	data_sram_addr_byte,

	dm_addr_illegal
);
	input [2:0]load_store_mem;
	input [1:0]data_sram_addr_byte;
	output reg dm_addr_illegal;

	always @(*) begin
		case(load_store_mem)
			3'b010,3'b011,3'b110: begin	//lh,lhu,sh
				dm_addr_illegal <= data_sram_addr_byte[0];
			end
			3'b100,3'b111: begin	//lw,sw
				dm_addr_illegal <= data_sram_addr_byte[1] | data_sram_addr_byte[0];
			end
			default: begin
				dm_addr_illegal <= 0;
			end
		endcase
	end // always @(*)
endmodule