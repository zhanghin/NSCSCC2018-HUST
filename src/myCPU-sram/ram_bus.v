module ins_sram_adapter(
	clk,
	rst,
	ins_read,
	ins_sram_stall,
	dirty
);
	input wire clk,rst;
	input wire ins_read;
	output wire ins_sram_stall;
	output reg dirty;
	assign ins_sram_stall = ins_read && ~dirty;
	always@(posedge clk)begin
		if(!rst)begin
			dirty<=0;
		end
		else if(ins_read==1)begin
			if(dirty==0)begin
				dirty<=1;	//如果当前周期访问停机，下一周期解除停机
			end
		end
		if(dirty==1) begin//任意时刻，dirty恢复到0接受访问请求
			dirty<=0;
		end
	end
endmodule

module data_sram_adapter(
	clk,
	rst,
	data_read,
	data_write,
	data_sram_stall,
	dirty
);
	input wire clk,rst;
	input wire data_read;
	input wire data_write;
	output wire data_sram_stall;
	output reg dirty;
	assign data_sram_stall = (data_read || data_write)&& ~dirty;
	always@(posedge clk)begin
		if(!rst)begin
			dirty<=0;
		end
		else if(data_read==1 || data_write == 1)begin
			if(dirty==0)begin
				dirty<=1;	//如果当前周期访问停机，下一周期解除停机
			end
		end
		if(dirty==1) begin//任意时刻，dirty恢复到0接受访问请求
			dirty<=0;
		end
	end
endmodule