module dram_mode (
	load_store_mem,
	data_sram_addr_byte_mem,
	//dm_addr_illegal_mem,

	mode_mem
);
	input [2:0]load_store_mem;
	input [1:0]data_sram_addr_byte_mem;
	//input dm_addr_illegal_mem;
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
				endcase // data_sram_addr_byte_mem
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
				endcase // data_sram_addr_byte_mem
				//mode_mem <= data_sram_addr_byte_mem[1] ? 4'b1100 : 4'b0011;
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
		if(sw) begin
			mode <= 4'b1111;
		end // if(sw | lw)
		else if(sb) begin
			case(pc_id_byte[1:0])
				2'b00: begin
					mode <= 4'b0001;
				end // 2'b00:
				2'b01: begin
					mode <= 4'b0010;
				end // 2'b01:
				2'b10: begin
					mode <= 4'b0100;
				end // 2'b10:
				2'b11: begin
					mode <= 4'b1000;
				end // 2'b11:
				default : begin
					mode <= 4'b0000;
				end // default :
			endcase // pc_id_byte[1:0]
		end // else if(lb|lbu|sb)
		else if(sh) begin
			case(pc_id_byte[1])
				1'b0: begin
					mode <= 4'b0011;
				end // 1'b0:
				1'b1: begin
					mode <= 4'b1100;
				end // 1'b1:
				default : begin
					mode <= 4'b0000;
				end // default :
			endcase // pc_id_byte[1]
		end // else if(lh|lhu|sh)
		else begin
			mode <= 4'b0000;
		end // else*/