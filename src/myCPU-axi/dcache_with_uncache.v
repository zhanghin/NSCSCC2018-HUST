/*
**  作者：林力韬
**  功能：数据cache\指令cache\uncache，与AXI接口对接实现AXI协议
*/

`define UNCACHE_OFFSET 16'h1faf //根据需要特定该地址段uncache访问

/*
dcache_with_uncache实现的是一个带有uncache访问功能的cache,可用于数据cache，
内部有dcache\uncache模块实例化各一个，可以根据地址区间选择访问请求经过的模块
*/
module DCache_with_UnCache #(parameter
	CACHE_LINE_WIDTH = 6,	//CacheLine的大小，字节地址，减去2等于offset长度，该值不能大于9
	TAG_WIDTH = 20,	//Tag的长度
	NUM_ROADS = 2	//组相联路数
	`define NUM_CACHE_GOUPS (2 ** `INDEX_WIDTH)
) (
	// Clock and reset
	input  wire rst,
	input  wire clk,

	// AXI Bus 
	//input
    input wire AXI_rd_dready,//读访问，总线上数据就绪可写Cache的控制信号
    input wire AXI_rd_last,//读访问,标识总线上当前数据是最后一个数据字的控制信号
    input wire[31:0] AXI_rd_data,//读访问总线给出的数据
    input wire AXI_rd_addr_clear,//读请求地址已经被响应，可以清除请求信号

    input wire AXI_wr_next,//写访问，总线允许送下一个数据的控制信号
    input wire AXI_wr_ok,//写访问，总线标识收到从设备最后一个ACK的控制信号
    input wire AXI_wr_addr_clear,//写请求地址已经被响应，可以清除请求信号

    //output
    output wire [31:0]AXI_addr,//送总线地址；
    output wire  AXI_addr_valid,//送总线地址有效的控制信号，意味着总线访问请求
    output wire  AXI_we,//送总线标记访问是读还是写的控制信号
    output wire [2:0]AXI_size,
    output wire [7:0]AXI_lens,//读访问，送总线size/length
    output wire  AXI_rd_rready,//送总线，主设备就绪读数据的控制信号

    output wire [31:0]AXI_wr_data,//写访问，送总线的数据
    output wire AXI_wr_dready,//写访问，送总线一个字数据就绪的控制信号
    output wire [3:0]AXI_byte_enable,//写访问，送总线写操作各个字节使能的控制信号
    output wire AXI_wr_last,//写访问，送总线表示当前数据是最后一个数据字的控制信号
    output wire AXI_response_rready,//写访问，送总线表示就绪接收从设备ACK的信号

	// CPU i/f
	input  wire [31:0] cpu_addr,//CPU访问地址
	input  wire [3:0]  cpu_byteenable,//CPU访问模式
	input  wire        cpu_read,//CPU读命令
	input  wire        cpu_write,//CPU写命令
	input  wire        cpu_hitwriteback,//CPU强制写穿命令
	input  wire        cpu_hitinvalidate,//CPU强制失效命令
	input  wire [31:0] cpu_wrdata,//CPU写数据
	output wire [31:0] cpu_rddata,//发往CPU读到的数据
	output wire        cpu_stall,//发往CPU停机等待信号

	input  wire        cpu_addr_illegal,//CPU地址错信号
	input  wire        new_lw_ins_tocache//CPU上一周期正常运转，到达Cache的是新的访存请求信号
);

	//如果illegal 终止访存，取消CPU访存指令
	wire addr_illegal;
	wire [3:0] legal_cpu_byteenable;
	wire legal_cpu_read;
	wire legal_cpu_write;
	wire legal_cpu_hitwriteback;
	wire legal_cpu_hitinvalidate;
	assign addr_illegal = cpu_addr_illegal;
	assign legal_cpu_byteenable = addr_illegal? 4'b0000 : cpu_byteenable;
	assign legal_cpu_read = addr_illegal? 0 : cpu_read;
	assign legal_cpu_write = addr_illegal? 0 : cpu_write;
	assign legal_cpu_hitwriteback = addr_illegal? 0 : cpu_hitwriteback;
	assign legal_cpu_hitinvalidate = addr_illegal? 0 : cpu_hitinvalidate;

	//判断地址是否cacheable，这里做了简化处理，在MIPS体系结构下该功能交给MMU处理，由MMU给出控制信号
	wire cpu_kseg0_uncache;
	assign cpu_kseg0_uncache  = (cpu_addr[31:16]==`UNCACHE_OFFSET) && (cpu_read || cpu_write);

	//信号声明
    wire DCache_AXI_rd_dready;
    wire DCache_AXI_rd_last;
    wire [31:0] DCache_AXI_rd_data;
    wire DCache_AXI_rd_addr_clear;
    wire DCache_AXI_wr_next;
    wire DCache_AXI_wr_ok;
    wire DCache_AXI_wr_addr_clear;
    wire [31:0]DCache_AXI_addr;
    wire DCache_AXI_addr_valid;
    wire DCache_AXI_we;
    wire [2:0]DCache_AXI_size;
    wire [7:0]DCache_AXI_lens;
    wire DCache_AXI_rd_rready;
    wire [31:0]DCache_AXI_wr_data;
    wire DCache_AXI_wr_dready;
    wire[3:0]DCache_AXI_byte_enable;
    wire DCache_AXI_wr_last;
    wire DCache_AXI_response_rready;
	wire [31:0] DCache_cpu_addr;
	wire [3:0]  DCache_cpu_byteenable;
	wire DCache_cpu_read;
	wire DCache_cpu_write;
	wire DCache_cpu_hitwriteback;
	wire DCache_cpu_hitinvalidate;
	wire [31:0] DCache_cpu_wrdata;
	wire [31:0] DCache_cpu_rddata;
	wire        DCache_cpu_stall;

	wire UnCache_AXI_rd_dready;
    wire UnCache_AXI_rd_last;
    wire [31:0] UnCache_AXI_rd_data;
    wire UnCache_AXI_rd_addr_clear;
    wire UnCache_AXI_wr_next;
    wire UnCache_AXI_wr_ok;
    wire UnCache_AXI_wr_addr_clear;
    wire [31:0]UnCache_AXI_addr;
    wire UnCache_AXI_addr_valid;
    wire UnCache_AXI_we;
    wire [2:0]UnCache_AXI_size;
    wire [7:0]UnCache_AXI_lens;
    wire UnCache_AXI_rd_rready;
    wire [31:0]UnCache_AXI_wr_data;
    wire UnCache_AXI_wr_dready;
    wire[3:0]UnCache_AXI_byte_enable;
    wire UnCache_AXI_wr_last;
    wire UnCache_AXI_response_rready;
	wire [31:0] UnCache_cpu_addr;
	wire [3:0]  UnCache_cpu_byteenable;
	wire UnCache_cpu_read;
	wire UnCache_cpu_write;
	wire UnCache_cpu_hitwriteback;
	wire UnCache_cpu_hitinvalidate;
	wire [31:0] UnCache_cpu_wrdata;
	wire [31:0] UnCache_cpu_rddata;
	wire        UnCache_cpu_stall;

	//如果uncache高电平使用UnCache输入输出，否则使用DCache输入输出
	//input
	assign UnCache_AXI_rd_dready = AXI_rd_dready;
	assign DCache_AXI_rd_dready = AXI_rd_dready;
	assign UnCache_AXI_rd_last = AXI_rd_last;
	assign DCache_AXI_rd_last = AXI_rd_last;
	assign UnCache_AXI_rd_data = AXI_rd_data;
	assign DCache_AXI_rd_data = AXI_rd_data;
	assign UnCache_AXI_rd_addr_clear = AXI_rd_addr_clear;
	assign DCache_AXI_rd_addr_clear = AXI_rd_addr_clear;

	assign UnCache_AXI_wr_next = AXI_wr_next;
	assign DCache_AXI_wr_next = AXI_wr_next;
	assign UnCache_AXI_wr_ok = AXI_wr_ok;
	assign DCache_AXI_wr_ok = AXI_wr_ok;
	assign UnCache_AXI_wr_addr_clear = AXI_wr_addr_clear;
	assign DCache_AXI_wr_addr_clear = AXI_wr_addr_clear;

    //output
    assign AXI_addr = cpu_kseg0_uncache? UnCache_AXI_addr : DCache_AXI_addr ;//送总线地址；
    assign AXI_addr_valid = cpu_kseg0_uncache? UnCache_AXI_addr_valid : DCache_AXI_addr_valid ;//送总线地址有效的控制信号
    assign AXI_we = cpu_kseg0_uncache? UnCache_AXI_we : DCache_AXI_we ;//送总线标记访问是读还是写的控制信号
    assign AXI_size = cpu_kseg0_uncache? UnCache_AXI_size : DCache_AXI_size ;
    assign AXI_lens = cpu_kseg0_uncache? UnCache_AXI_lens : DCache_AXI_lens ;//读访问，送总线size/length
    assign AXI_rd_rready = cpu_kseg0_uncache? UnCache_AXI_rd_rready : DCache_AXI_rd_rready ;//送总线，主设备就绪读数据的控制信号

    assign AXI_wr_data = cpu_kseg0_uncache? UnCache_AXI_wr_data : DCache_AXI_wr_data ;//写访问，送总线的数据
    assign AXI_wr_dready = cpu_kseg0_uncache? UnCache_AXI_wr_dready : DCache_AXI_wr_dready ;//写访问，送总线一个字数据就绪的控制信号
    assign AXI_byte_enable = cpu_kseg0_uncache? UnCache_AXI_byte_enable : DCache_AXI_byte_enable ;//写访问，送总线写字节使能的控制信号
    assign AXI_wr_last = cpu_kseg0_uncache? UnCache_AXI_wr_last : DCache_AXI_wr_last ;//写访问，送总线表示当前数据是最后一个数据字的控制信号
    assign AXI_response_rready = cpu_kseg0_uncache?  UnCache_AXI_response_rready : DCache_AXI_response_rready ;

	// CPU i/f

	assign UnCache_cpu_byteenable = cpu_kseg0_uncache? legal_cpu_byteenable : 0 ;//CPU访问模式
	assign UnCache_cpu_read = cpu_kseg0_uncache? legal_cpu_read : 0 ;//CPU读命令
	assign UnCache_cpu_write = cpu_kseg0_uncache? legal_cpu_write : 0 ;//CPU写命令
	assign UnCache_cpu_hitwriteback = cpu_kseg0_uncache? legal_cpu_hitwriteback : 0 ;//CPU强制写穿命令
	assign UnCache_cpu_hitinvalidate = cpu_kseg0_uncache? legal_cpu_hitinvalidate : 0 ;//CPU强制失效命令


	assign DCache_cpu_byteenable = cpu_kseg0_uncache? 0 : legal_cpu_byteenable ;//CPU访问模式
	assign DCache_cpu_read = cpu_kseg0_uncache? 0 : legal_cpu_read ;//CPU读命令
	assign DCache_cpu_write = cpu_kseg0_uncache? 0 : legal_cpu_write ;//CPU写命令
	assign DCache_cpu_hitwriteback = cpu_kseg0_uncache? 0 : legal_cpu_hitwriteback ;//CPU强制写穿命令
	assign DCache_cpu_hitinvalidate = cpu_kseg0_uncache? 0 : legal_cpu_hitinvalidate ;//CPU强制失效命令

	wire [31:0]cpu_addr_real;
	assign cpu_addr_real = {cpu_addr[31:2],2'b00};
	assign UnCache_cpu_addr = cpu_addr;
	assign DCache_cpu_addr = cpu_addr_real;

	assign UnCache_cpu_wrdata = cpu_wrdata;
	assign DCache_cpu_wrdata = cpu_wrdata;

	//CPU output
	assign cpu_rddata = addr_illegal? 0:(cpu_kseg0_uncache?  UnCache_cpu_rddata : DCache_cpu_rddata) ;//发往CPU读到的数据
	assign cpu_stall = cpu_kseg0_uncache? UnCache_cpu_stall : DCache_cpu_stall ;//发往CPU停机等待信号

	DCache #(
		.CACHE_LINE_WIDTH(CACHE_LINE_WIDTH),	//CacheLine的大小，字节地址，减去2等于offset长度，该值不能大于9
		.TAG_WIDTH (TAG_WIDTH),	//Tag的长度
		.NUM_ROADS(NUM_ROADS)	//组相联路数
	) _inter_DCache(
		// Clock and reset
		.rst(rst),.clk(clk),
		// AXI Bus 
		//input
	    .AXI_rd_dready(DCache_AXI_rd_dready),//读访问，总线上数据就绪可写Cache的控制信号
	    .AXI_rd_last(DCache_AXI_rd_last),//读访问,标识总线上当前数据是最后一个数据字的控制信号
	    .AXI_rd_data(DCache_AXI_rd_data),//读访问总线给出的数据
	    .AXI_rd_addr_clear(DCache_AXI_rd_addr_clear),//读请求地址已经被响应信号

	    .AXI_wr_next(DCache_AXI_wr_next),//写访问，总线允许送下一个数据的控制信号
	    .AXI_wr_ok(DCache_AXI_wr_ok),//写访问，总线标识收到从设备最后一个ACK的控制信号
	    .AXI_wr_addr_clear(DCache_AXI_wr_addr_clear),//写请求地址已经被响应信号

	    //output
	    .AXI_addr(DCache_AXI_addr),//送总线地址；
	    .AXI_addr_valid(DCache_AXI_addr_valid),//送总线地址有效的控制信号
	    .AXI_we(DCache_AXI_we),//送总线标记访问是读还是写的控制信号
	    .AXI_size(DCache_AXI_size),
	    .AXI_lens(DCache_AXI_lens),//读访问，送总线size/length
	    .AXI_rd_rready(DCache_AXI_rd_rready),//送总线，主设备就绪读数据的控制信号

	    .AXI_wr_data(DCache_AXI_wr_data),//写访问，送总线的数据
	    .AXI_wr_dready(DCache_AXI_wr_dready),//写访问，送总线一个字数据就绪的控制信号
	    .AXI_byte_enable(DCache_AXI_byte_enable),//写访问，送总线写字节使能的控制信号
	    .AXI_wr_last(DCache_AXI_wr_last),//写访问，送总线表示当前数据是最后一个数据字的控制信号
	    .AXI_response_rready(DCache_AXI_response_rready),

		// CPU i/f
		.cpu_addr(DCache_cpu_addr),//CPU访问地址
		.cpu_byteenable(DCache_cpu_byteenable),//CPU访问模式
		.cpu_read(DCache_cpu_read),//CPU读命令
		.cpu_write(DCache_cpu_write),//CPU写命令
		.cpu_hitwriteback(DCache_cpu_hitwriteback),//CPU强制写穿命令
		.cpu_hitinvalidate(DCache_cpu_hitinvalidate),//CPU强制失效命令
		.cpu_wrdata(DCache_cpu_wrdata),//CPU写数据
		.cpu_rddata(DCache_cpu_rddata),//发往CPU读到的数据
		.cpu_stall(DCache_cpu_stall)//发往CPU停机等待信号
	);



	UnCache _inter_UnCache(
		// Clock and reset
		.rst(rst),.clk(clk),
		// AXI Bus 
		//input
	    .AXI_rd_dready(UnCache_AXI_rd_dready),//读访问，总线上数据就绪可写Cache的控制信号
	    .AXI_rd_last(UnCache_AXI_rd_last),//读访问,标识总线上当前数据是最后一个数据字的控制信号
	    .AXI_rd_data(UnCache_AXI_rd_data),//读访问总线给出的数据
	    .AXI_rd_addr_clear(UnCache_AXI_rd_addr_clear),//读请求地址已经被响应信号

	    .AXI_wr_next(UnCache_AXI_wr_next),//写访问，总线允许送下一个数据的控制信号
	    .AXI_wr_ok(UnCache_AXI_wr_ok),//写访问，总线标识收到从设备最后一个ACK的控制信号
	    .AXI_wr_addr_clear(UnCache_AXI_wr_addr_clear),//写请求地址已经被响应信号

	    //output
	    .AXI_addr(UnCache_AXI_addr),//送总线地址；
	    .AXI_addr_valid(UnCache_AXI_addr_valid),//送总线地址有效的控制信号
	    .AXI_we(UnCache_AXI_we),//送总线标记访问是读还是写的控制信号
	    .AXI_size(UnCache_AXI_size),
	    .AXI_lens(UnCache_AXI_lens),//读访问，送总线size/length
	    .AXI_rd_rready(UnCache_AXI_rd_rready),//送总线，主设备就绪读数据的控制信号

	    .AXI_wr_data(UnCache_AXI_wr_data),//写访问，送总线的数据
	    .AXI_wr_dready(UnCache_AXI_wr_dready),//写访问，送总线一个字数据就绪的控制信号
	    .AXI_byte_enable(UnCache_AXI_byte_enable),//写访问，送总线写字节使能的控制信号
	    .AXI_wr_last(UnCache_AXI_wr_last),//写访问，送总线表示当前数据是最后一个数据字的控制信号
	    .AXI_response_rready(UnCache_AXI_response_rready),

		// CPU i/f
		.cpu_addr(UnCache_cpu_addr),//CPU访问地址
		.cpu_byteenable(UnCache_cpu_byteenable),//CPU访问模式
		.cpu_read(UnCache_cpu_read),//CPU读命令
		.cpu_write(UnCache_cpu_write),//CPU写命令
		.cpu_hitwriteback(UnCache_cpu_hitwriteback),//CPU强制写穿命令
		.cpu_hitinvalidate(UnCache_cpu_hitinvalidate),//CPU强制失效命令
		.cpu_wrdata(UnCache_cpu_wrdata),//CPU写数据
		.cpu_rddata(UnCache_cpu_rddata),//发往CPU读到的数据
		.cpu_stall(UnCache_cpu_stall),//发往CPU停机等待信号
		.cpu_new_ins(new_lw_ins_tocache)//CPU上一周期正常运转，到达Cache的是新的访存请求信号
	);

endmodule

/*
icache实现的是一个不带有uncache访问功能的cache,总是cacheable,可用于指令cache，
内部只有dcache模块实例化，不需要选择访存请求经过的模块
*/
module ICache #(parameter
	CACHE_LINE_WIDTH = 6,	//CacheLine的大小，字节地址，减去2等于offset长度，该值不能大于9
	TAG_WIDTH = 20,	//Tag的长度
	NUM_ROADS = 2	//组相联路数
	`define NUM_CACHE_GOUPS (2 ** `INDEX_WIDTH)
) (
	// Clock and reset
	input  wire rst,
	input  wire clk,

	// AXI Bus 
	//input
    input wire AXI_rd_dready,//读访问，总线上数据就绪可写Cache的控制信号
    input wire AXI_rd_last,//读访问,标识总线上当前数据是最后一个数据字的控制信号
    input wire[31:0] AXI_rd_data,//读访问总线给出的数据
    input wire AXI_rd_addr_clear,//读请求地址已经被响应信号

    input wire AXI_wr_next,//写访问，总线允许送下一个数据的控制信号
    input wire AXI_wr_ok,//写访问，总线标识收到从设备最后一个ACK的控制信号
    input wire AXI_wr_addr_clear,//写请求地址已经被响应信号

    //output
    output wire [31:0]AXI_addr,//送总线地址；
    output wire  AXI_addr_valid,//送总线地址有效的控制信号
    output wire  AXI_we,//送总线标记访问是读还是写的控制信号
    output wire [2:0]AXI_size,
    output wire [7:0]AXI_lens,//读访问，送总线size/length
    output wire  AXI_rd_rready,//送总线，主设备就绪读数据的控制信号

    output wire [31:0]AXI_wr_data,//写访问，送总线的数据
    output wire AXI_wr_dready,//写访问，送总线一个字数据就绪的控制信号
    output wire [3:0]AXI_byte_enable,//写访问，送总线写字节使能的控制信号
    output wire AXI_wr_last,//写访问，送总线表示当前数据是最后一个数据字的控制信号
    output wire AXI_response_rready,//写访问，送总线表示就绪接收从设备ACK的信号

	// CPU i/f
	input  wire [31:0] cpu_addr,//CPU访问地址
	input  wire [3:0]  cpu_byteenable,//CPU访问模式
	input  wire        cpu_read,//CPU读命令
	input  wire        cpu_write,//CPU写命令
	input  wire        cpu_hitwriteback,//CPU强制写穿命令
	input  wire        cpu_hitinvalidate,//CPU强制失效命令
	input  wire [31:0] cpu_wrdata,//CPU写数据
	output wire [31:0] cpu_rddata,//发往CPU读到的数据
	output wire        cpu_stall,//发往CPU停机等待信号

	input  wire        cpu_addr_illegal,//CPU地址错信号
	input  wire        new_lw_ins_tocache//CPU上一周期正常运转，到达Cache的是新的访存请求信号
);

	//如果illegal 终止访存，取消CPU访存指令
	wire addr_illegal;
	wire [3:0] legal_cpu_byteenable;
	wire legal_cpu_read;
	wire legal_cpu_write;
	wire legal_cpu_hitwriteback;
	wire legal_cpu_hitinvalidate;
	assign addr_illegal = cpu_addr_illegal;
	assign legal_cpu_byteenable = addr_illegal? 4'b0000 : cpu_byteenable;
	assign legal_cpu_read = addr_illegal? 0 : cpu_read;
	assign legal_cpu_write = addr_illegal? 0 : cpu_write;
	assign legal_cpu_hitwriteback = addr_illegal? 0 : cpu_hitwriteback;
	assign legal_cpu_hitinvalidate = addr_illegal? 0 : cpu_hitinvalidate;

	//信号声明
    wire DCache_AXI_rd_dready;
    wire DCache_AXI_rd_last;
    wire [31:0] DCache_AXI_rd_data;
    wire DCache_AXI_rd_addr_clear;
    wire DCache_AXI_wr_next;
    wire DCache_AXI_wr_ok;
    wire DCache_AXI_wr_addr_clear;
    wire [31:0]DCache_AXI_addr;
    wire DCache_AXI_addr_valid;
    wire DCache_AXI_we;
    wire [2:0]DCache_AXI_size;
    wire [7:0]DCache_AXI_lens;
    wire DCache_AXI_rd_rready;
    wire [31:0]DCache_AXI_wr_data;
    wire DCache_AXI_wr_dready;
    wire[3:0]DCache_AXI_byte_enable;
    wire DCache_AXI_wr_last;
    wire DCache_AXI_response_rready;
	wire [31:0] DCache_cpu_addr;
	wire [3:0]  DCache_cpu_byteenable;
	wire DCache_cpu_read;
	wire DCache_cpu_write;
	wire DCache_cpu_hitwriteback;
	wire DCache_cpu_hitinvalidate;
	wire [31:0] DCache_cpu_wrdata;
	wire [31:0] DCache_cpu_rddata;
	wire        DCache_cpu_stall;

	//总是使用DCache输入输出
	//input
	assign DCache_AXI_rd_dready = AXI_rd_dready;
	assign DCache_AXI_rd_last = AXI_rd_last;
	assign DCache_AXI_rd_data = AXI_rd_data;
	assign DCache_AXI_rd_addr_clear = AXI_rd_addr_clear;

	assign DCache_AXI_wr_next = AXI_wr_next;
	assign DCache_AXI_wr_ok = AXI_wr_ok;
	assign DCache_AXI_wr_addr_clear = AXI_wr_addr_clear;

    //output
    assign AXI_addr =  DCache_AXI_addr ;//送总线地址；
    assign AXI_addr_valid =  DCache_AXI_addr_valid ;//送总线地址有效的控制信号
    assign AXI_we =  DCache_AXI_we ;//送总线标记访问是读还是写的控制信号
    assign AXI_size =  DCache_AXI_size ;
    assign AXI_lens =  DCache_AXI_lens ;//读访问，送总线size/length
    assign AXI_rd_rready =DCache_AXI_rd_rready ;//送总线，主设备就绪读数据的控制信号

    assign AXI_wr_data =  DCache_AXI_wr_data ;//写访问，送总线的数据
    assign AXI_wr_dready =  DCache_AXI_wr_dready ;//写访问，送总线一个字数据就绪的控制信号
    assign AXI_byte_enable =  DCache_AXI_byte_enable ;//写访问，送总线写字节使能的控制信号
    assign AXI_wr_last =  DCache_AXI_wr_last ;//写访问，送总线表示当前数据是最后一个数据字的控制信号
    assign AXI_response_rready =  DCache_AXI_response_rready ;

	// CPU i/f
	assign DCache_cpu_byteenable =  legal_cpu_byteenable ;//CPU访问模式
	assign DCache_cpu_read =  legal_cpu_read ;//CPU读命令
	assign DCache_cpu_write =  legal_cpu_write ;//CPU写命令
	assign DCache_cpu_hitwriteback =  legal_cpu_hitwriteback ;//CPU强制写穿命令
	assign DCache_cpu_hitinvalidate =  legal_cpu_hitinvalidate ;//CPU强制失效命令

	wire [31:0]cpu_addr_real;
	assign cpu_addr_real = {cpu_addr[31:2],2'b00};
	assign DCache_cpu_addr = cpu_addr_real;
	assign DCache_cpu_wrdata = cpu_wrdata;

	//CPU output
	assign cpu_rddata = addr_illegal? 0: DCache_cpu_rddata ;//发往CPU读到的数据
	assign cpu_stall = DCache_cpu_stall ;//发往CPU停机等待信号

	DCache #(
		.CACHE_LINE_WIDTH(CACHE_LINE_WIDTH),	//CacheLine的大小，字节地址，减去2等于offset长度，该值不能大于9
		.TAG_WIDTH (TAG_WIDTH),	//Tag的长度
		.NUM_ROADS(NUM_ROADS)	//组相联路数
	) _inter_ICache(
		// Clock and reset
		.rst(rst),.clk(clk),
		// AXI Bus 
		//input
	    .AXI_rd_dready(DCache_AXI_rd_dready),//读访问，总线上数据就绪可写Cache的控制信号
	    .AXI_rd_last(DCache_AXI_rd_last),//读访问,标识总线上当前数据是最后一个数据字的控制信号
	    .AXI_rd_data(DCache_AXI_rd_data),//读访问总线给出的数据
	    .AXI_rd_addr_clear(DCache_AXI_rd_addr_clear),//读请求地址已经被响应信号

	    .AXI_wr_next(DCache_AXI_wr_next),//写访问，总线允许送下一个数据的控制信号
	    .AXI_wr_ok(DCache_AXI_wr_ok),//写访问，总线标识收到从设备最后一个ACK的控制信号
	    .AXI_wr_addr_clear(DCache_AXI_wr_addr_clear),//写请求地址已经被响应信号

	    //output
	    .AXI_addr(DCache_AXI_addr),//送总线地址；
	    .AXI_addr_valid(DCache_AXI_addr_valid),//送总线地址有效的控制信号
	    .AXI_we(DCache_AXI_we),//送总线标记访问是读还是写的控制信号
	    .AXI_size(DCache_AXI_size),
	    .AXI_lens(DCache_AXI_lens),//读访问，送总线size/length
	    .AXI_rd_rready(DCache_AXI_rd_rready),//送总线，主设备就绪读数据的控制信号

	    .AXI_wr_data(DCache_AXI_wr_data),//写访问，送总线的数据
	    .AXI_wr_dready(DCache_AXI_wr_dready),//写访问，送总线一个字数据就绪的控制信号
	    .AXI_byte_enable(DCache_AXI_byte_enable),//写访问，送总线写字节使能的控制信号
	    .AXI_wr_last(DCache_AXI_wr_last),//写访问，送总线表示当前数据是最后一个数据字的控制信号
	    .AXI_response_rready(DCache_AXI_response_rready),

		// CPU i/f
		.cpu_addr(DCache_cpu_addr),//CPU访问地址
		.cpu_byteenable(DCache_cpu_byteenable),//CPU访问模式
		.cpu_read(DCache_cpu_read),//CPU读命令
		.cpu_write(DCache_cpu_write),//CPU写命令
		.cpu_hitwriteback(DCache_cpu_hitwriteback),//CPU强制写穿命令
		.cpu_hitinvalidate(DCache_cpu_hitinvalidate),//CPU强制失效命令
		.cpu_wrdata(DCache_cpu_wrdata),//CPU写数据
		.cpu_rddata(DCache_cpu_rddata),//发往CPU读到的数据
		.cpu_stall(DCache_cpu_stall)//发往CPU停机等待信号
	);

endmodule

/*
cacheline是cache最基本的存储体模块，除了存储信息数据外，最主要功能是根据字节使能信号写入数据
一个cache_group由多个cacheline构成，多个cache_group构成cache整体
*/
module CacheLine #(parameter
	CACHE_LINE_WIDTH = 6,
	TAG_WIDTH = 18
	`define OFFSET_WIDTH (CACHE_LINE_WIDTH-2)//注意，OFFSET_WIDTH不能长于7位，即每Cache行不大于128B
) (
	// Clock and reset
	input  wire rst,
	input  wire clk,

	input  wire [`OFFSET_WIDTH-1:0] rd_off,

	output wire [TAG_WIDTH-1:0]     rd_tag,
	output reg  [31:0]              rd_data,
	output wire                     rd_dirty,
	output wire                     rd_valid,

	input  wire                     wr_write,
	input  wire [TAG_WIDTH-1:0]     wr_tag,
	input  wire [`OFFSET_WIDTH-1:0] wr_off,
	input  wire [31:0]              wr_data,
	input  wire [3:0]               wr_byte_enable,
	input  wire                     wr_dirty,
	input  wire                     wr_valid
);

	// Storage
	reg [TAG_WIDTH-1:0] tag;
	reg [31:0] data[2**`OFFSET_WIDTH - 1 : 0];
	reg dirty;
	reg valid;
	reg [31:0] dout;

	// Reading data
	assign rd_tag = tag;
	assign rd_dirty = valid ? dirty : 0;
	assign rd_valid = valid;

	// Resetting or writing data
	always @(posedge clk, negedge rst) begin
		if (~rst) begin : rst_data
			// Resetting
			dirty <= 1'b0;
			valid <= 1'b0;
			tag   <= 0;

		end else if (wr_write) begin
			// Writing data
			tag   <= wr_tag;
			dirty <= wr_dirty;
			valid <= wr_valid;

		end
	end

	integer k;
	always @(posedge clk) begin : proc_bram
		if(wr_write) begin
			for(k=0; k<4; k=k+1)
				if (wr_byte_enable[k]) begin
					data[wr_off][k*8 +: 8] <= wr_data[k*8 +: 8];
					//dout[k*8 +: 8] <= wr_data[k*8 +: 8];
				end
		end
	end

	always @(*) begin
		rd_data = valid ? data[rd_off] : 0;
	end

endmodule


/*
cache组是cache最重要的模块，其主要功能是实现命中查找、随机替换策略、寻找空的cache行等等
注意，MIPS体系结构中cache指令中有全组选中失效或同步的功能，cachegroup模块没有实现这一功能
多个cache_group构成cache整体，由地址的INDEX字段索引
*/
module CacheGroup #(parameter
	CACHE_LINE_WIDTH = 6,
	TAG_WIDTH = 18,
	NUM_ROADS = 2	//组相联路数
	`define OFFSET_WIDTH (CACHE_LINE_WIDTH-2)//注意，OFFSET_WIDTH不能长于7位，即每Cache行不大于128B
) (
	// Clock and reset
	input  wire rst,
	input  wire clk,
	//目标地址与目标偏移
	input  wire [`OFFSET_WIDTH-1:0] rd_off,
	input  wire [TAG_WIDTH-1:0] rd_aim_tag,
	input  wire [31:0] rand,
	//读出的数据
	output wire [TAG_WIDTH-1:0]     rd_tag_output,
	output wire [31:0]              rd_data_output,
	output wire                     rd_dirty_output,
	output wire                     rd_valid_output,
	output wire 					rd_hit_output,
	output wire 					full,
	//需要写入的数据
	input  wire                     write_cache,
	input  wire [`OFFSET_WIDTH-1:0] wr_off,
	input  wire [TAG_WIDTH-1:0]     wr_tag,
	input  wire [31:0]              wr_data,
	input  wire [3:0]               wr_byte_enable,
	input  wire                     wr_dirty,
	input  wire                     wr_valid
);

	// Wires to cache lines
	wire [TAG_WIDTH-1:0]     rd_tag[NUM_ROADS-1:0];
	wire [31:0]              rd_data[NUM_ROADS-1:0];
	wire                     rd_dirty[NUM_ROADS-1:0];
	wire                     rd_valid[NUM_ROADS-1:0];
	wire                     wr_write[NUM_ROADS-1:0];

	// Storage
	genvar i;
	generate for (i = 0; i < NUM_ROADS; i = i + 1) begin
	CacheLine #(
		.CACHE_LINE_WIDTH (CACHE_LINE_WIDTH),
		.TAG_WIDTH        (TAG_WIDTH)
	) lines (
		.rst(rst), .clk(clk),

		.rd_tag(rd_tag[i]), .rd_off(rd_off),
		.rd_data(rd_data[i]), .rd_dirty(rd_dirty[i]),
		.rd_valid(rd_valid[i]),

		.wr_write(wr_write[i]),
		.wr_tag(wr_tag), .wr_off(wr_off),
		.wr_data(wr_data), .wr_byte_enable(wr_byte_enable),
		.wr_dirty(wr_dirty), .wr_valid(wr_valid)
	);
	end endgenerate

	//获取命中情况下的数据
	wire [TAG_WIDTH-1:0]     rd_tag_hit;
	wire [31:0]              rd_data_hit;
	wire                     rd_dirty_hit;
	wire                     rd_valid_hit;
	reg [31:0]				 rd_tag_index;
	reg [31:0]               j;
	always @(*) begin
		//从rd_tag[i],rd_data[i],rd_dirty[i],rd_valid[i]选择rd_tag[i]==rd_aim_tag的CacheLine
		rd_tag_index <= 0;
		 for (j = 0; j < NUM_ROADS; j = j + 1) begin
			if(rd_tag[j]==rd_aim_tag & rd_valid[j]) begin
				rd_tag_index <= j;
			end
		end 
	end
	assign rd_tag_hit = rd_tag[rd_tag_index];
	assign rd_data_hit = rd_data[rd_tag_index];
	assign rd_dirty_hit = rd_dirty[rd_tag_index];
	assign rd_valid_hit = rd_valid[rd_tag_index];

	assign rd_hit_output = rd_valid_hit && (rd_tag_hit == rd_aim_tag) ;

	//获取随机情况下的数据
	wire[31:0] rand_id;
	assign rand_id = rand;
	reg [TAG_WIDTH-1:0]     rd_tag_rand;
	reg [31:0]              rd_data_rand;
	reg                     rd_dirty_rand;
	reg                     rd_valid_rand;
	always @(*) begin
		rd_tag_rand <= rd_tag[rand_id];
		rd_data_rand <= rd_data[rand_id];
		rd_dirty_rand <= rd_dirty[rand_id];
		rd_valid_rand <= rd_valid[rand_id];
	end
	
	//计算首个INVALID的空行位置,并计算是否没有空行
	wire 	rd_invalid_we[NUM_ROADS-1:0];
	wire 	rd_invalid_temp[NUM_ROADS-1:0];
	//wire 	full;
	generate for (i = 0; i < NUM_ROADS; i = i + 1) begin
		if(i==0)	begin 
			assign rd_invalid_we[i]=~rd_valid[i];
			assign rd_invalid_temp[i]=rd_invalid_we[i];
		end else if(i>0) 	
			begin assign rd_invalid_we[i]=~rd_valid[i] & ~rd_invalid_temp[i-1];
			assign rd_invalid_temp[i]=rd_invalid_we[i] | rd_invalid_temp[i-1];
		end
	end endgenerate
	assign full = ~rd_invalid_temp[NUM_ROADS-1];


	//在hit\invalid\rand中选中一个送到输出
	assign rd_tag_output = rd_hit_output?rd_tag_hit:(full?rd_tag_rand:0);
	assign rd_data_output = rd_hit_output?rd_data_hit:(full?rd_data_rand:0);
	assign rd_dirty_output = rd_hit_output?rd_dirty_hit:(full?rd_dirty_rand:0);
	assign rd_valid_output = rd_hit_output?rd_valid_hit:(full?rd_valid_rand:0);


	//对tag命中的行,给出写使能选择信号;未命中写使能信号给空行,若已满给随机一行
	wire   wr_write_hit[NUM_ROADS-1:0];
	wire   wr_write_rand[NUM_ROADS-1:0];
	wire   wr_write_invalid[NUM_ROADS-1:0];
	generate for (i = 0; i < NUM_ROADS; i = i + 1) begin
		assign wr_write_hit[i] = write_cache ? ((rd_tag[i] == rd_aim_tag) && rd_valid[i]) : 1'b0;
		assign wr_write_rand[i] = write_cache ? (i == rand_id):1'b0;
		assign wr_write_invalid[i] = write_cache ? rd_invalid_we[i]:1'b0;
		assign wr_write[i] = rd_hit_output?wr_write_hit[i]:(full?wr_write_rand[i]:wr_write_invalid[i]);
	end endgenerate

endmodule

/*
Sign_Copy模块将一个输入数据拷贝到2个寄存器中，用于电路扇出优化
这里使用DONT_TOUCH = "true"命令防止VIVADO综合布线时将该模块优化掉
*/
(*DONT_TOUCH = "true"*)  module Sign_Copy#(
	parameter  SIGN_WIDTH = 1)(
	input		[SIGN_WIDTH-1:0]  need_copy,
	output reg  [SIGN_WIDTH-1:0]  copy_sign_1,
	output reg  [SIGN_WIDTH-1:0]  copy_sign_0
	);
    always @(need_copy) begin
        copy_sign_1 <= need_copy;
        copy_sign_0 <= need_copy;
    end 
endmodule

`define CACHE_FSM_IDLE					3'd0
`define CACHE_FSM_WRITEBACK_WAIT		3'd1
`define CACHE_FSM_WRITEBACK				3'd3
`define CACHE_FSM_MEMREAD_WAIT			3'd4
`define CACHE_FSM_MEMREAD				3'd5
`define CACHE_FSM_WAIT_WRITE			3'd6
`define CACHE_FSM_WRITEBACK_WAITOVER	3'd7

`define AXI_1bytes_SIZE 3'b000
`define AXI_2bytes_SIZE 3'b001
`define AXI_4bytes_SIZE 3'b010
`define AXI_8bytes_SIZE 3'b011
`define AXI_16bytes_SIZE 3'b100
`define AXI_32bytes_SIZE 3'b101
`define AXI_64bytes_SIZE 3'b110
`define AXI_128bytes_SIZE 3'b111

/*
DCache是cache整体，它除了包含多个cache_group存储体外，还有AXI状态机，通过和AXI interface模块交互，
实现AXI协议的功能
*/
module DCache #(parameter
	CACHE_LINE_WIDTH = 6,	//CacheLine的大小，字节地址，减去2等于offset长度，该值不能大于9
	TAG_WIDTH = 18,	//Tag的长度
	NUM_ROADS = 2	//组相联路数
	`define NUM_CACHE_GOUPS (2 ** `INDEX_WIDTH)
	`define OFFSET_WIDTH (CACHE_LINE_WIDTH-2)//注意，OFFSET_WIDTH不能长于7位，即每Cache行不大于128B
	`define INDEX_WIDTH (32 - CACHE_LINE_WIDTH - TAG_WIDTH)
) (
	// Clock and reset
	input  wire rst,
	input  wire clk,

	// AXI Bus 

	//input
    input wire AXI_rd_dready,//读访问，总线上数据就绪可写Cache的控制信号
    input wire AXI_rd_last,//读访问,标识总线上当前数据是最后一个数据字的控制信号
    input wire[31:0] AXI_rd_data,//读访问总线给出的数据
    input wire AXI_rd_addr_clear,//读请求地址已经被响应信号

    input wire AXI_wr_next,//写访问，总线允许送下一个数据的控制信号
    input wire AXI_wr_ok,//写访问，总线标识收到从设备最后一个ACK的控制信号
    input wire AXI_wr_addr_clear,//写请求地址已经被响应信号

    //output
    output wire [31:0]AXI_addr,//送总线地址；
    output reg  AXI_addr_valid,//送总线地址有效的控制信号
    output reg  AXI_we,//送总线标记访问是读还是写的控制信号
    output wire [2:0]AXI_size,
    output wire [7:0]AXI_lens,//读访问，送总线size/length
    output reg  AXI_rd_rready,//送总线，主设备就绪读数据的控制信号

    output wire [31:0]AXI_wr_data,//写访问，送总线的数据
    output reg AXI_wr_dready,//写访问，送总线一个字数据就绪的控制信号
    output reg [3:0]AXI_byte_enable,//写访问，送总线写字节使能的控制信号
    output reg AXI_wr_last,//写访问，送总线表示当前数据是最后一个数据字的控制信号
    output reg AXI_response_rready,//写访问，送总线表示就绪接收从设备ACK的信号

	// CPU i/f
	input  wire [31:0] cpu_addr,//CPU访问地址
	input  wire [3:0]  cpu_byteenable,//CPU访问模式
	input  wire        cpu_read,//CPU读命令
	input  wire        cpu_write,//CPU写命令
	input  wire        cpu_hitwriteback,//CPU强制写穿命令
	input  wire        cpu_hitinvalidate,//CPU强制失效命令
	input  wire [31:0] cpu_wrdata,//CPU写数据
	output wire [31:0] cpu_rddata,//发往CPU读到的数据
	output wire        cpu_stall//发往CPU停机等待信号

);
	//AXI SIZE MAP
	assign AXI_size =`AXI_4bytes_SIZE;
	assign AXI_lens = (2**`OFFSET_WIDTH)-1 ;//突发次数=lens+1

	// Wires to cache groups	
	wire [`OFFSET_WIDTH-1:0] rd_off;
	wire [TAG_WIDTH-1:0] rd_aim_tag;
	reg  [31:0] rand;

	wire [TAG_WIDTH-1:0]     rd_tag_output[`NUM_CACHE_GOUPS-1:0];
	wire [31:0]              rd_data_output[`NUM_CACHE_GOUPS-1:0];
	wire                     rd_dirty_output[`NUM_CACHE_GOUPS-1:0];
	wire                     rd_valid_output[`NUM_CACHE_GOUPS-1:0];
	wire   					 rd_hit_output[`NUM_CACHE_GOUPS-1:0];
	wire                     full[`NUM_CACHE_GOUPS-1:0];

	wire                      write_cache[`NUM_CACHE_GOUPS-1:0];
	wire [TAG_WIDTH-1:0] 	  rd_aim_tag_tocache;
	wire [TAG_WIDTH-1:0] 	  wr_tag_tocache;
	wire  [`OFFSET_WIDTH-1:0] wr_off_tocache;
	wire  [31:0]              wr_data_tocache;
	wire  [3:0]               wr_byte_enable_tocache;
	wire                      wr_dirty_tocache;
	wire                      wr_valid_tocache;

	reg  [TAG_WIDTH-1:0]     wr_tag;
	reg  [`OFFSET_WIDTH-1:0] wr_off;
	reg  [31:0]              wr_data;
	reg  [3:0]               wr_byte_enable;
	reg                      wr_dirty;
	reg                      wr_valid;



	//对大扇出信号进行寄存器分发，减少电路延迟
	genvar i;
	genvar j;
	//_rd_off_信号分发，减少扇出
	wire [`OFFSET_WIDTH - 1:0] rd_off_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  rd_off_temp_vector[0] = rd_off;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (`OFFSET_WIDTH)) 
		    	 _Sign_Copy(
				.need_copy( rd_off_temp_vector[2**i-1+j]),
				.copy_sign_1(rd_off_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(rd_off_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_rd_aim_tag_tocache_信号分发，减少扇出
	wire [TAG_WIDTH - 1:0] rd_aim_tag_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  rd_aim_tag_tocache_temp_vector[0] = rd_aim_tag_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (TAG_WIDTH)) 
		    	 _Sign_Copy(
				.need_copy( rd_aim_tag_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(rd_aim_tag_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(rd_aim_tag_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_rand_信号分发，减少扇出
	wire [31:0] rand_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  rand_temp_vector[0] = rand;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (32)) 
		    	 _Sign_Copy(
				.need_copy( rand_temp_vector[2**i-1+j]),
				.copy_sign_1(rand_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(rand_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_off_tocache_信号分发，减少扇出
	wire [`OFFSET_WIDTH - 1:0]wr_off_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_off_tocache_temp_vector[0] = wr_off_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (`OFFSET_WIDTH)) 
		    	_Sign_Copy( 
				.need_copy( wr_off_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_off_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_off_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_tag_tocache_信号分发，减少扇出
	wire [TAG_WIDTH - 1:0] wr_tag_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_tag_tocache_temp_vector[0] = wr_tag_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (TAG_WIDTH)) 
		    	 _Sign_Copy(
				.need_copy( wr_tag_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_tag_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_tag_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_data_tocache_信号分发，减少扇出
	wire [31:0] wr_data_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_data_tocache_temp_vector[0] = wr_data_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (32)) 
		    	 _Sign_Copy(
				.need_copy( wr_data_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_data_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_data_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_byte_enable_tocache_信号分发，减少扇出
	wire [3:0] wr_byte_enable_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_byte_enable_tocache_temp_vector[0] = wr_byte_enable_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (4)) 
		    	 _Sign_Copy(
				.need_copy( wr_byte_enable_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_byte_enable_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_byte_enable_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_dirty_tocache_信号分发，减少扇出
	wire  wr_dirty_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_dirty_tocache_temp_vector[0] = wr_dirty_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (1)) 
		    	 _Sign_Copy(
				.need_copy( wr_dirty_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_dirty_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_dirty_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	//_wr_valid_tocache_信号分发，减少扇出
	wire  wr_valid_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  wr_valid_tocache_temp_vector[0] = wr_valid_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (1)) 
		    	 _Sign_Copy(
				.need_copy( wr_valid_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(wr_valid_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(wr_valid_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

	// Storage
	generate for (i = 0; i < `NUM_CACHE_GOUPS; i = i + 1) begin
	CacheGroup #(
		.CACHE_LINE_WIDTH (CACHE_LINE_WIDTH),
		.TAG_WIDTH        (TAG_WIDTH),
		.NUM_ROADS 		  (NUM_ROADS)
	) _cache_groups (
	// Clock and reset
	.rst(rst),.clk(clk),
	//目标地址与目标偏移
	.rd_off(rd_off_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.rd_aim_tag(rd_aim_tag_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.rand(rand_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	//读出的数据
	.rd_tag_output(rd_tag_output[i]),
	.rd_data_output(rd_data_output[i]),
	.rd_dirty_output(rd_dirty_output[i]),
	.rd_valid_output(rd_valid_output[i]),
	.rd_hit_output(rd_hit_output[i]),
	.full(full[i]),
	//需要写入的数据
	.write_cache(write_cache[i]),
	.wr_off(wr_off_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.wr_tag(wr_tag_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.wr_data(wr_data_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.wr_byte_enable(wr_byte_enable_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.wr_dirty(wr_dirty_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]),
	.wr_valid(wr_valid_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i])
	);
	end endgenerate

	//状态机
	reg [2:0] state;

	//获取CPU地址中的索引、标识、偏移量
	wire [TAG_WIDTH-1:0]     cache_addr_cpu_tag;
	wire [`INDEX_WIDTH-1:0]  cache_addr_idx;
	wire [`OFFSET_WIDTH-1:0] cache_addr_cpu_off;
	wire [1:0]               cache_addr_dropoff;
	assign {
		cache_addr_cpu_tag,  cache_addr_idx,
		cache_addr_cpu_off,  cache_addr_dropoff
	} = cpu_addr;
	assign rd_aim_tag = cache_addr_cpu_tag;

	//对CacheLine调度时需要调整offset部分
	reg  [`OFFSET_WIDTH-1:0] cache_addr_access_off;//用于调整地址的offset部分
	wire [`OFFSET_WIDTH-1:0] cache_addr_off = (
		state == `CACHE_FSM_IDLE ?
		cache_addr_cpu_off : cache_addr_access_off
	);
	reg  [TAG_WIDTH-1:0] cache_addr_mem_tag;	//用于访问RAM的地址tag和offset
	reg  [`OFFSET_WIDTH-1:0] cache_addr_mem_off;
	wire [`OFFSET_WIDTH-1:0] cache_end_off = 0 - 1;


	wire cg_valid = rd_valid_output[cache_addr_idx];
	wire cg_dirty = rd_dirty_output[cache_addr_idx];
	wire [TAG_WIDTH-1:0]     cg_tag   = rd_tag_output[cache_addr_idx];
	wire [31:0]              cg_data  = rd_data_output[cache_addr_idx];
    wire cg_hit   = rd_hit_output[cache_addr_idx];
    wire cg_full  = full[cache_addr_idx];


	assign AXI_wr_data = cg_data;//传输的数据
	// AXI access address
	assign AXI_addr = {
		cache_addr_mem_tag,  cache_addr_idx,
		cache_addr_mem_off,  2'b0
	};

	// Logic
	wire need_invalidate = cg_valid && cg_hit && cpu_hitinvalidate;//命中有效且需要无效化
	wire need_writeback = (	//读写未命中有效脏在无空行时回写，强制失效写回在命中有效脏时回写
		cg_valid && cg_dirty && cg_full && ((cpu_read  && ~cg_hit) || (cpu_write && ~cg_hit)) // wr
		||	cg_valid && cg_dirty && ((cpu_hitwriteback || cpu_hitinvalidate) && cg_hit)
	);
	wire need_replace = (	//如果是一般写回，valid不变，如果是hitinvalidate写回或full写回，valid置为0
		cg_valid && cg_dirty && cg_full && ((cpu_read  && ~cg_hit) || (cpu_write && ~cg_hit)) // wr
		||	cg_valid && cg_dirty && (cpu_hitinvalidate && cg_hit)
	);
	wire need_memread = (
		(cpu_read  && (~cg_valid || ~cg_hit)) || // rd
		(cpu_write && (~cg_valid || ~cg_hit)) // wr
	);

    //写入使能与数据重定向所需的声明
	reg  write_cache_reg;
	wire write_cache_signal;
	//reg  [`INDEX_WIDTH-1:0] write_idx;
	wire [`INDEX_WIDTH-1:0] write_idx_tocache;
	wire cpu_write_or_invalidate;
	wire cpu_need_write;
	wire cpu_need_invalidate;

	//_write_cache_signal_信号分发，减少扇出
	wire  write_cache_signal_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  write_cache_signal_temp_vector[0] = write_cache_signal;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (1)) 
		    	 _Sign_Copy(
				.need_copy(write_cache_signal_temp_vector[2**i-1+j]),
				.copy_sign_1(write_cache_signal_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(write_cache_signal_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

    //_write_idx_tocache_信号分发，减少扇出
	wire  [`INDEX_WIDTH-1:0] write_idx_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1):0];
	assign  write_idx_tocache_temp_vector[0] = write_idx_tocache;
	generate 
		for(i=0;i<`INDEX_WIDTH;i=i+1)begin
	    	for(j=0;j<(2**i);j=j+1)begin
		    	Sign_Copy#(.SIGN_WIDTH        (`INDEX_WIDTH)) 
		    	 _Sign_Copy(
				.need_copy(write_idx_tocache_temp_vector[2**i-1+j]),
				.copy_sign_1(write_idx_tocache_temp_vector[2**(i+1)-1+j*2+1]),
				.copy_sign_0(write_idx_tocache_temp_vector[2**(i+1)-1+j*2+0])
				);
	    	end
	    end
    endgenerate

    //将write_cache_signal作用于需要写入的cache组
	generate for (i = 0; i < `NUM_CACHE_GOUPS; i = i + 1) begin
		assign write_cache[i] = write_cache_signal_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i] ?
		 (i == write_idx_tocache_temp_vector[(2**(`INDEX_WIDTH+1)-1) - (2**(`INDEX_WIDTH)) + i]) : 1'b0;
	end endgenerate

	//单周期写入信号控制逻辑
	assign cpu_write_or_invalidate = 
	(state==`CACHE_FSM_IDLE)&&(cpu_write==1'b1||need_invalidate==1'b1)&&~(need_writeback||need_memread);
	assign cpu_need_write=(state==`CACHE_FSM_IDLE)&&(cpu_write==1'b1);
	assign cpu_need_invalidate=(state==`CACHE_FSM_IDLE)&&(need_invalidate==1'b1);

	//单周期写入选路逻辑
	assign rd_off = cpu_write_or_invalidate?cache_addr_cpu_off:cache_addr_off;
	assign write_cache_signal = cpu_write_or_invalidate?1'b1:write_cache_reg;
	assign wr_off_tocache = cpu_write_or_invalidate?cache_addr_off:wr_off;
	assign wr_tag_tocache = cpu_write_or_invalidate?rd_aim_tag:wr_tag;
	assign wr_data_tocache = cpu_write_or_invalidate?cpu_wrdata:wr_data;
	assign wr_byte_enable_tocache = cpu_write_or_invalidate?(cpu_need_write?cpu_byteenable:4'b0000):wr_byte_enable;
	assign wr_dirty_tocache = cpu_write_or_invalidate?(cpu_need_write?1'b1:1'b0):wr_dirty;
	assign wr_valid_tocache = cpu_write_or_invalidate?(cpu_need_write?1'b1:1'b0):wr_valid;
	assign rd_aim_tag_tocache = rd_aim_tag;
	assign write_idx_tocache = cache_addr_idx;

	// To cpu
	assign cpu_stall = (
		state != `CACHE_FSM_IDLE ||
		need_writeback || need_memread
	);
	assign cpu_rddata = cg_data;

// FSM controller
	always @(posedge clk, negedge rst) begin
		if (~rst) begin //异步复位，同步动作
			//AXI总线空闲
			AXI_addr_valid<=1'b0;
			//总线信号清除
			AXI_response_rready<=0;
			AXI_we<=1'b0;
			AXI_rd_rready<=1'b0;
			AXI_wr_dready<=1'b0;
			AXI_byte_enable<=4'b0000;
			AXI_wr_last<=1'b0;
			//内部寄存器清零
			rand<=0;
			wr_tag<=0;
			wr_off<=0;
			wr_data<=0;
			wr_byte_enable<=0;
			wr_dirty<=0;
			wr_valid<=0;
			cache_addr_access_off<=0;
			cache_addr_mem_tag<=0;
			cache_addr_mem_off<=0;
			write_cache_reg<=0;
			//FSM状态为空闲
			state <= `CACHE_FSM_IDLE;
		end else begin
			case (state)
				`CACHE_FSM_IDLE: begin
					if (need_writeback) begin //需要进行一次替换
						state <= `CACHE_FSM_WRITEBACK;
						//需要替换意味着肯定发生MISS,cg_tag是被替换行的tag,需要传输到总线上
						cache_addr_mem_tag <= cg_tag;
						//内部Cache访问地址寄存器偏移量置为0，从头开始写
						cache_addr_access_off <= 0;
						cache_addr_mem_off <= 0;
						//write_cache_reg <= 1'b0;
						//总线信号操作
						AXI_byte_enable<=4'b1111;
						AXI_we <= 1'b1;
						AXI_addr_valid <= 1'b1;
						AXI_wr_dready <= 1'b1;
						
					end else if (need_memread) begin //访存优先级低于替换，先替换后访存
						state <= `CACHE_FSM_MEMREAD_WAIT;
						//需要访存意味着肯定发生MISS,cpu_tag是要访存的tag,需要传输到总线上
						cache_addr_mem_tag <= cache_addr_cpu_tag;
						//内部Cache访问地址寄存器偏移量置为0，从头开始读
						cache_addr_access_off <= 0;
						cache_addr_mem_off <= 0;
						//write_cache_reg <= 1'b0;
						//总线信号操作
						AXI_byte_enable<=4'b1111;
						AXI_we <= 1'b0;
						AXI_addr_valid <= 1'b1;
						AXI_rd_rready <=1'b1;

					end else if (cpu_write) begin  //写不存在MISS情况下，执行CPU写指令
						state <= `CACHE_FSM_IDLE;
						
					end else if (need_invalidate) begin //在不存在MISS情况下，需要使相应CacheLine失效
						state <= `CACHE_FSM_IDLE;
						
					end
					// 读命中是组合逻辑，立即可以给出数据
				end

				`CACHE_FSM_WRITEBACK: begin
					if(AXI_wr_addr_clear)begin
						//撤销总线请求信号
						AXI_addr_valid <= 1'b0;
					end
					if (AXI_wr_next == 1'b1) begin //总线可用
						//准备下一个字的发送
						cache_addr_access_off <= cache_addr_access_off + 1;
						cache_addr_mem_off <= cache_addr_mem_off + 1;
						//撤销总线请求信号，但CPU继续停等
						AXI_addr_valid <= 1'b0;
						AXI_addr_valid <= 1'b0;
						AXI_wr_dready <= 1'b1;
						if (cache_addr_mem_off == cache_end_off - 1) begin //地址偏移到CacheLine最后一个字
							AXI_response_rready <= 1;
							AXI_wr_last<=1;//发送完成ACK
							// 结束写内存操作，对CacheLine的dirty位置0,其他不变
							write_cache_reg <= 1'b1;
							if(need_replace == 1)
								wr_valid<=0;
							else
								wr_valid <=1;
							//如果是一般写回，valid不变，如果是hitinvalidate写回或full写回，valid置为0
							wr_dirty <= 0;
	                        wr_off <= cache_addr_off;
							wr_tag <= cg_tag;
							wr_data <= 0;
							wr_byte_enable <= 4'b0000;

							state <= `CACHE_FSM_WRITEBACK_WAITOVER;
						end
					end
					//若总线忙则等待
				end

				`CACHE_FSM_WRITEBACK_WAITOVER: begin
					AXI_addr_valid <= 1'b0;
					write_cache_reg <= 1'b0;  //结束对Cache的最后一次写回				
					if (AXI_wr_ok == 1'b1) begin //总线传输结束
						//总线信号操作
						AXI_wr_dready <= 1'b0;
						AXI_byte_enable <= 4'b0000;
						AXI_we <= 0;
						AXI_wr_last <= 0;
						//下次随机替换下一行
						if(rand == NUM_ROADS-1)	rand<=0;
						else rand<=rand+1;
						AXI_response_rready <= 0;
						state <= `CACHE_FSM_IDLE;
					end
					//若总线无响应则等待
				end

				`CACHE_FSM_MEMREAD_WAIT: begin
					if(AXI_rd_addr_clear)begin
						//撤销总线请求信号
						AXI_addr_valid <= 1'b0;
					end
					if (AXI_rd_dready == 1'b1) begin //总线有数据
						//准备下一个字的接收
						cache_addr_access_off <= cache_addr_access_off + 1;
                        cache_addr_mem_off <= cache_addr_mem_off + 1;
                        //对Cache的写入
						wr_dirty <= 1'b0;
						wr_valid <= 1'b0;
                        wr_off <= cache_addr_access_off;
						wr_tag <= cache_addr_mem_tag;
						wr_byte_enable <= 4'b1111;
						wr_data <= AXI_rd_data;
						write_cache_reg <= 1'b1;
						//撤销总线请求信号，但CPU继续停等
						AXI_addr_valid <= 1'b0;
						//总线信号操作
						AXI_rd_rready <= 1'b1;
						state <= `CACHE_FSM_MEMREAD;
					end else begin
						//总线无响应则等待
						write_cache_reg <= 1'b0;
					end
				end

				`CACHE_FSM_MEMREAD: begin
					if(AXI_rd_addr_clear)begin
						//撤销总线请求信号
						AXI_addr_valid <= 1'b0;
					end
					if (cache_addr_mem_off == cache_end_off) begin  //地址偏移加到溢出为0表示发送结束
							wr_valid <= 1'b1;
					end else begin
							wr_valid <= 1'b0;
					end
					if (AXI_rd_dready == 1'b1) begin //总线有数据
						AXI_addr_valid <= 1'b0;
						if (cache_addr_mem_off == cache_end_off) begin  //地址偏移加到溢出为0表示发送结束
							state <= `CACHE_FSM_WAIT_WRITE;
						end
						//准备下一个字的接收
						cache_addr_access_off <= cache_addr_access_off + 1;
						cache_addr_mem_off <= cache_addr_mem_off + 1;
                        //对Cache的写入
						wr_dirty <= 1'b0;
                        wr_off <= cache_addr_access_off;
						wr_tag <= cache_addr_mem_tag;
						wr_byte_enable <= 4'b1111;
						wr_data <= AXI_rd_data;
						write_cache_reg <= 1'b1;
					end else begin
						//若总线无响应则等待
						write_cache_reg <= 1'b0;
					end
				end
				`CACHE_FSM_WAIT_WRITE: begin
					write_cache_reg <= 1'b0;  //结束对Cache的最后一次写回
					AXI_addr_valid <= 1'b0;
					state <= `CACHE_FSM_IDLE;
				end
				default: begin
					state <= `CACHE_FSM_IDLE;
				end
			endcase
		end
	end


endmodule

/*
uncache模块包含有AXI状态机，通过和AXI interface模块交互，实现AXI协议的功能。
使得CPU可以直接访问AXI总线，但一次传输一个字，没有实现非对齐访问。
*/
module UnCache(
	// Clock and reset
	input  wire rst,
	input  wire clk,

	// AXI Bus 
	//input
    input wire AXI_rd_dready,//读访问，总线上数据就绪可写Cache的控制信号
    input wire AXI_rd_last,//读访问,标识总线上当前数据是最后一个数据字的控制信号
    input wire[31:0] AXI_rd_data,//读访问总线给出的数据
    input wire AXI_rd_addr_clear,//读请求地址已经被响应信号

    input wire AXI_wr_next,//写访问，总线允许送下一个数据的控制信号
    input wire AXI_wr_ok,//写访问，总线标识收到从设备最后一个ACK的控制信号
    input wire AXI_wr_addr_clear,//写请求地址已经被响应信号

    //output
    output wire [31:0]AXI_addr,//送总线地址；
    output reg  AXI_addr_valid,//送总线地址有效的控制信号
    output reg  AXI_we,//送总线标记访问是读还是写的控制信号
    output wire [2:0]AXI_size,
    output wire [7:0]AXI_lens,//读访问，送总线size/length
    output reg  AXI_rd_rready,//送总线，主设备就绪读数据的控制信号

    output wire [31:0]AXI_wr_data,//写访问，送总线的数据
    output reg AXI_wr_dready,//写访问，送总线一个字数据就绪的控制信号
    output reg [3:0]AXI_byte_enable,//写访问，送总线写字节使能的控制信号
    output reg AXI_wr_last,//写访问，送总线表示当前数据是最后一个数据字的控制信号
    output reg AXI_response_rready,

	// CPU i/f
	input  wire [31:0] cpu_addr,//CPU访问地址
	input  wire [3:0]  cpu_byteenable,//CPU访问模式
	input  wire        cpu_read,//CPU读命令
	input  wire        cpu_write,//CPU写命令
	input  wire        cpu_hitwriteback,//CPU强制写穿命令
	input  wire        cpu_hitinvalidate,//CPU强制失效命令
	input  wire [31:0] cpu_wrdata,//CPU写数据
	output wire [31:0] cpu_rddata,//发往CPU读到的数据
	output wire        cpu_stall,//发往CPU停机等待信号
	input  wire        cpu_new_ins

);
	//AXI SIZE MAP
	assign AXI_size = `AXI_4bytes_SIZE;
	assign AXI_lens = 8'b0;//一次突发只发送一次数据

	//状态机
	reg [2:0] state;
	//reg dirty;
	reg stall_valid;
	assign AXI_wr_data = cpu_wrdata;//传输的数据
	assign AXI_addr = cpu_addr;
	// To cpu
	assign cpu_stall = (
		(state != `CACHE_FSM_IDLE ||
		((state == `CACHE_FSM_IDLE) && cpu_new_ins && (cpu_read || cpu_write))) && ~stall_valid
	);

	reg[31:0] mem_rd_data;
	assign cpu_rddata = mem_rd_data;

// FSM controller
	always @(posedge clk, negedge rst) begin
		if (~rst) begin //异步复位，同步动作
			//AXI总线空闲
			AXI_addr_valid<=1'b0;
			//总线信号清除
			AXI_response_rready<=0;
			AXI_we<=1'b0;
			AXI_rd_rready<=1'b0;
			AXI_wr_dready<=1'b0;
			AXI_byte_enable<=4'b0000;
			AXI_wr_last<=1'b0;
			//内部寄存器清零
			mem_rd_data<=0;
			state <= `CACHE_FSM_IDLE;
			stall_valid <= 0;
		end else begin
			case (state)
				`CACHE_FSM_IDLE: begin
					stall_valid <= 0;
					if (cpu_write && cpu_new_ins) begin
						//地址,数据总是就绪
						//总线信号操作
						AXI_byte_enable<=cpu_byteenable;
						AXI_we <= 1'b1;
						AXI_addr_valid <= 1'b1;
						AXI_wr_dready <= 1'b1;
						AXI_wr_last<=1;//发送完成ACK
						AXI_response_rready <= 1;
						state <= `CACHE_FSM_WRITEBACK_WAITOVER;
					end else if (cpu_read && cpu_new_ins) begin //访存优先级低于替换，先替换后访存
						state <= `CACHE_FSM_MEMREAD_WAIT;
						//地址总是就绪
						//总线信号操作
						AXI_byte_enable<=cpu_byteenable;
						AXI_we <= 1'b0;
						AXI_addr_valid <= 1'b1;
						AXI_rd_rready <=1'b1;
					end
				end

				`CACHE_FSM_WRITEBACK_WAITOVER: begin
					if(AXI_wr_addr_clear)begin
						//撤销总线请求信号
						AXI_addr_valid <= 1'b0;
					end
					if (AXI_wr_ok == 1'b1) begin //总线传输结束
						AXI_wr_dready <= 1'b0;
						AXI_addr_valid <= 1'b0;
						AXI_response_rready <= 0;
						AXI_byte_enable<=4'b0000;
						AXI_wr_last <=0;
						AXI_we <= 1'b0;
						//dirty <= 0;
						state <= `CACHE_FSM_IDLE;
						stall_valid <= 1;
					end
					//若总线无响应则等待
				end

				`CACHE_FSM_MEMREAD_WAIT: begin
					if(AXI_rd_addr_clear)begin
						//撤销总线请求信号
						AXI_addr_valid <= 1'b0;
					end
					if (AXI_rd_dready == 1'b1) begin //总线有数据
                        //记录送达的数据
						mem_rd_data<= AXI_rd_data;
						//撤销总线请求信号，但CPU继续停等
						AXI_addr_valid <= 1'b0;
						//总线信号操作
						AXI_rd_rready <= 1'b0;
						AXI_byte_enable<=4'b0000;
						state <= `CACHE_FSM_IDLE;
					end
				end
				default: begin
					state <= `CACHE_FSM_IDLE;
				end
			endcase
		end
	end

endmodule