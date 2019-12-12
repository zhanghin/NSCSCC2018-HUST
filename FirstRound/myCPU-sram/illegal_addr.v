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
			end // 3'b010,3'b011,3'b110:
			3'b100,3'b111: begin	//lw,sw
				dm_addr_illegal <= data_sram_addr_byte[1] | data_sram_addr_byte[0];
			end // 3'b100,3'b111:
			default: begin
				dm_addr_illegal <= 0;
			end // default:
		endcase // load_store_mem
	end // always @(*)
endmodule