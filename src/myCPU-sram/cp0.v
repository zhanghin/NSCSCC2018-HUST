
module cp0(
//output
        data_o, //[31:0] 读出的寄存器数据
        user_mode,//高电平表示运行在用户态，否则为内核态
        ebase, //[19:0]异常基址
        epc, //[31:0]EPC值
        tlb_config,//tlb配置字段
        allow_int,//中断使能
        software_int_o,//软中断输出
        hardware_int_o,//软中断输出
        interrupt_mask,//中断屏蔽
        special_int_vec,//特权级异常标记
        boot_exp_vec,//启动时异常标记
        asid,//地址空间
        int_exl,//异常级别
        kseg0_uncached,//uncached地址标记
//input
        clk, //上升沿驱动
        rst, //低电平复位
        stall,
        rd_addr, //[4:0]读寄存器编号
        rd_sel,//[2:0]读寄存器选择编号
        we, //1b写使能
        wr_addr, //[4:0]写寄存器编号
        wr_sel,  //[2:0]写寄存器选择编号
        data_i,  //[31:0]写数据
        hardware_int_in, //[4:0]外部硬件中断信号

        clean_exl,//eret执行时清除EXL例外标记
        en_exp, // 1b 发生异常信号
        exp_epc, //[31:0]异常的返回地址，放入EPC
        exp_bd,  // 1b 在分支延迟槽发生异常的信号
        exp_code, //[4:0] 异常代码
        exp_bad_vaddr, //[31:0] 地址相关异常发生地址
        exp_badv_we, // 1b 地址相关异常的信号，高电平有效
        exp_asid, //[7:0] 地址空间重填的值
        exp_asid_we // 1b 地址空间重填信号，高电平有效，一般为0
);
         //we_probe,
         //probe_result

wire [5:0]TLB_size;
assign TLB_size = 6'd15;//TLB共有15+1个表项

/*Linux 必备的一些CP0寄存器*/
`define CP0_Index {5'd0,3'd0}   
`define CP0_Random {5'd1,3'd0}
`define CP0_EntryLo0 {5'd2,3'd0}
`define CP0_EntryLo1 {5'd3,3'd0}
`define CP0_Context {5'd4,3'd0}
//0,1,2,3,4,5号寄存器与TLB相关
`define CP0_BadVAddr {5'd8,3'd0}
//8号寄存器表示最近的地址相关异常发生地址
`define CP0_Count {5'd9,3'd0}
//9号寄存器为计时器计数
`define CP0_EntryHi {5'd10,3'd0}
//10号寄存器与TLB相关
`define CP0_Compare {5'd11,3'd0}
//11号寄存器参与计时器比较
`define CP0_Status {5'd12,3'd0}
//12号寄存器为SR寄存器，保存CPU状态
`define CP0_Cause {5'd13,3'd0}
//13号寄存器保存异常或中断原因
`define CP0_EPC {5'd14,3'd0}
//14号寄存器为EPC异常程序计数器，保存返回地址
`define CP0_PRId {5'd15,3'd0}
//15号寄存器0号选择，为CPU版本与类型
`define CP0_EBase {5'd15,3'd1}
//15号寄存器1号选择，异常入口基址
`define CP0_Config {5'd16,3'd0}
//16号寄存器0号选择，CPU配置信息
`define CP0_Config1 {5'd16,3'd1}
//16号寄存器1号选择，CPU配置信息

input clk;
input rst;
input stall;
input[4:0] rd_addr; //读寄存器编号
input[2:0] rd_sel; //读寄存器选择编号
output [31:0] data_o; //读出的寄存器数据
input  we; //写使能
input [4:0] wr_addr; //写寄存器编号
input [2:0] wr_sel;  //写寄存器选择编号
input [31:0] data_i;  //写数据

input [5:0] hardware_int_in; //硬件中断信号

output  user_mode;  //CPU特权级
output [19:0] ebase;  //异常基址
output [31:0] epc;   //EPC值
output  allow_int;
output [89:0] tlb_config;
output [1:0] software_int_o;
output [5:0] hardware_int_o;
output [7:0] interrupt_mask;
output  special_int_vec;
output  boot_exp_vec;
output [7:0] asid;
output  int_exl;
output reg kseg0_uncached;

input  clean_exl;//写往SR(EXL)
input  en_exp; //发生异常信号
input [31:0] exp_epc;  //异常的返回地址，放入EPC
input  exp_bd;  //在分支延迟槽发生异常的信号
input [4:0] exp_code; //异常代码
input [31:0] exp_bad_vaddr; //地址相关异常发生地址
input  exp_badv_we; //地址相关异常的信号，高电平有效
input [7:0] exp_asid; //地址空间重填的值
input  exp_asid_we; //地址空间重填信号，高电平有效，一般为0
/*
input wire we_probe;
input wire[31:0] probe_result;
*/
reg[31:0] cp0_regs_Status;  //寄存器组
reg[31:0] cp0_regs_Cause;
reg[31:0] cp0_regs_Count;
reg[31:0] cp0_regs_Compare;
reg[31:0] cp0_regs_Context;
reg[31:0] cp0_regs_EPC;
reg[31:0] cp0_regs_EBase;
reg[31:0] cp0_regs_EntryLo1;
reg[31:0] cp0_regs_EntryLo0;
reg[31:0] cp0_regs_EntryHi;
reg[31:0] cp0_regs_Index;
reg[31:0] cp0_regs_Random;
reg[31:0] cp0_regs_BadVAddr;
reg[31:0] cp0_regs_Config;

wire[7:0] rd_addr_internal;    //内部读寄存器地址
reg[31:0] data_o_internal;     //内部数据寄存器
reg [5:0] hardware_int_in_sync;
reg [5:0] hardware_int;
reg timer_int;

assign rd_addr_internal = {rd_addr,rd_sel};    //拼接的寄存器地址
assign data_o = data_o_internal;    //读出数据为内部数据寄存器0的值

assign user_mode = cp0_regs_Status[4:1]==4'b1000; //CPU特权级
assign ebase = {2'b10, cp0_regs_EBase[29:12]};  //异常基址
assign epc = cp0_regs_EPC;  //EPC值

assign tlb_config = {
    cp0_regs_EntryLo0[5:3],
    cp0_regs_EntryLo1[5:3],
    cp0_regs_EntryHi[7:0],
    cp0_regs_EntryLo1[0] & cp0_regs_EntryLo0[0],
    cp0_regs_EntryHi[31:13],
    cp0_regs_EntryLo1[29:6],
    cp0_regs_EntryLo1[2:1],
    cp0_regs_EntryLo0[29:6],
    cp0_regs_EntryLo0[2:1],
    cp0_regs_Index[3:0]
};

assign hardware_int_o = cp0_regs_Cause[15:10];
//assign software_int_o = cp0_regs_Cause[9:8];
assign software_int_o = (we&&({wr_addr,wr_sel}==`CP0_Cause)) ? data_i[9:8] : cp0_regs_Cause[9:8];
assign interrupt_mask = cp0_regs_Status[15:8];
//assign special_int_vec = cp0_regs_Cause[23];
assign special_int_vec = (we&&({wr_addr,wr_sel}==`CP0_Cause)) ? 0 : cp0_regs_Cause[23];
assign boot_exp_vec = cp0_regs_Status[22];
assign asid = cp0_regs_EntryHi[7:0];
assign int_exl = cp0_regs_Status[1];

assign allow_int = cp0_regs_Status[2:0]==3'b001;

//处理外部中断与时间中断
always @(posedge clk) begin
    if(!rst)begin
        hardware_int_in_sync <= 0 ;
        hardware_int <= 0;
    end else begin
        hardware_int_in_sync <= {(timer_int | hardware_int_in[5]), hardware_int_in[4:0]};
        hardware_int <= hardware_int_in_sync;
    end
/*    $display("[12]Status:%h    [13]Cause:%h    [14]EPC:%h",cp0_regs_Status,cp0_regs_Cause,cp0_regs_EPC);
    $display("[08]BadVAddr:%h  [09]Count:%h    [11]Compare:%h",cp0_regs_BadVAddr,cp0_regs_Count,cp0_regs_Compare);
    $display("WE:%h            wr_cp0:%d       data_i:%h",we,{wr_addr,wr_sel},data_i);
    $display("Exp:%h  in_delayslot:%h   exp_code:%h    exp_epc:%h",en_exp,exp_bd,exp_code,exp_epc);*/
end

//处理读寄存器请求   
always @(*) begin
    if (!rst) begin
        data_o_internal <= 32'b0; //复位读出值为0
    end
    else 
        case(rd_addr_internal)
        `CP0_Compare: begin
            data_o_internal <= cp0_regs_Compare;
        end
        `CP0_Count: begin
            data_o_internal <= cp0_regs_Count;
        end
        `CP0_EBase: begin
            data_o_internal <= {2'b10, cp0_regs_EBase[29:12], 12'b0};
        end
        `CP0_EPC: begin
            data_o_internal <= cp0_regs_EPC;
        end
        `CP0_BadVAddr: begin
            data_o_internal <= cp0_regs_BadVAddr;
        end
        `CP0_Cause: begin
            data_o_internal <= {cp0_regs_Cause[31],7'b0,cp0_regs_Cause[23],7'b0, hardware_int, cp0_regs_Cause[9:8], 1'b0, cp0_regs_Cause[6:2], 2'b00};
        end
        `CP0_Status: begin
            data_o_internal <= cp0_regs_Status;
        end
        `CP0_Context: begin
            data_o_internal <= {cp0_regs_Context[31:4], 4'b0};
        end
        `CP0_EntryHi: begin
            data_o_internal <= {cp0_regs_EntryHi[31:13], 5'b0, cp0_regs_EntryHi[7:0]};
        end
        `CP0_EntryLo0: begin
            data_o_internal <= {2'b0, cp0_regs_EntryLo0[29:0]};
        end
        `CP0_EntryLo1: begin
            data_o_internal <= {2'b0, cp0_regs_EntryLo1[29:0]};
        end
        `CP0_Index: begin
            data_o_internal <= {cp0_regs_Index[31], 27'b0, cp0_regs_Index[3:0]};
        end
        `CP0_Random: begin
            data_o_internal <= cp0_regs_Random;
        end
        `CP0_PRId: begin 
            data_o_internal <= {8'b0, 8'b1, 16'h8000}; //MIPS32 4Kc
        end
        `CP0_Config: begin 
            data_o_internal <= {1'b1, 21'b0, 3'b1, 4'b0, cp0_regs_Config[2:0]}; //Release 1
        end
        `CP0_Config1: begin 
            //Cache Size:                            I:128-64B-direct, D:256-64B-direct
            data_o_internal <= {1'b0, TLB_size, 3'd1, 3'd5, 3'd0, 3'd2, 3'd5, 3'd0, 7'd0}; 
        end
        default:
            data_o_internal <= 32'b0;
        endcase
end

//处理寄存器写入
always @(posedge clk) begin
    if (!rst) begin  //复位为0
        cp0_regs_Count <= 32'd1;
        cp0_regs_Compare <= 32'd0;
        //cp0_regs_Status <= 32'h10400004; //BEV=1,ERL=1 is required,for Linux
        cp0_regs_Status <= 32'h00400001; //BEV=1,IE=1 is required for FuncTest
        cp0_regs_EBase <= 32'h80000000;
        cp0_regs_Cause[9:8] <= 2'b0;
        cp0_regs_Cause[23] <= 1'b0;
        cp0_regs_Cause <=0;//be required for FuncTest
        timer_int <= 1'b0;
        kseg0_uncached <= 1'b0;
        cp0_regs_Random <= TLB_size;
    end
    else begin
        cp0_regs_Count <= cp0_regs_Count+1'b0;//停用时间中断
        //cp0_regs_Count <= cp0_regs_Count+1'b1;
        if(cp0_regs_Compare != 32'b0 && cp0_regs_Compare==cp0_regs_Count) begin
            timer_int <= 1'b1;
        end

        if(cp0_regs_Random == 0)
            cp0_regs_Random <= TLB_size;
        else
            cp0_regs_Random <= cp0_regs_Random - 1'b1;

        if(we & stall) begin
            case({wr_addr,wr_sel})
            `CP0_Compare: begin
                timer_int <= 1'b0;
                cp0_regs_Compare <= data_i;
            end
            `CP0_Count: begin
                cp0_regs_Count <= data_i;
            end
            `CP0_EBase: begin
                cp0_regs_EBase[29:12] <= data_i[29:12]; //only bits 29..12 is writable
            end
            `CP0_EPC: begin
                cp0_regs_EPC <= data_i;
            end
            `CP0_Cause: begin
                cp0_regs_Cause[9:8] <= data_i[9:8];//for FuncTest
                //cp0_regs_Cause[23] <= data_i[23]; //IV for Linux
            end
            `CP0_Status: begin
                //cp0_regs_Status[28] <= data_i[28]; //CU0
                //cp0_regs_Status[22] <= data_i[22]; //BEV
                cp0_regs_Status[15:8] <= data_i[15:8]; //IM for FuncTest
               // cp0_regs_Status[4] <= data_i[4]; //UM
                //cp0_regs_Status[2:0] <= data_i[2:0]; //ERL, EXL, IE
                cp0_regs_Status[1:0] <= data_i[1:0]; //EXL, IE for FuncTest
            end
            `CP0_EntryHi: begin
                cp0_regs_EntryHi[31:13] <= data_i[31:13];
                cp0_regs_EntryHi[7:0] <= data_i[7:0];
            end
            `CP0_EntryLo0: begin
                cp0_regs_EntryLo0[29:0] <= data_i[29:0];
            end
            `CP0_EntryLo1: begin
                cp0_regs_EntryLo1[29:0] <= data_i[29:0];
            end
            `CP0_Index: begin
                cp0_regs_Index[3:0] <= data_i[3:0];
            end
            `CP0_Random: begin
                cp0_regs_Random <= data_i;
            end
            `CP0_Context: begin
                cp0_regs_Context[31:23] <= data_i[31:23];
            end
            `CP0_Config: begin 
                cp0_regs_Config[2:0] <= data_i[2:0];
                kseg0_uncached <= data_i[2:0]==3'd2;
            end

            endcase
        end
        /*
        if(we_probe)
            cp0_regs_Index <= probe_result;
        */
        //发生中断
        if(en_exp & stall) begin //发生异常
            if(exp_badv_we) //记录地址相关异常相关地址
                cp0_regs_BadVAddr <= exp_bad_vaddr;
            cp0_regs_Context[22:4] <= exp_bad_vaddr[31:13]; //填写VPN2虚页号
            cp0_regs_EntryHi[31:13] <= exp_bad_vaddr[31:13]; //填写VPN2虚页号

            if(exp_asid_we) //发生地址空间重填
                cp0_regs_EntryHi[7:0] <= exp_asid;
            if(cp0_regs_Status[1]==0 )begin
                cp0_regs_EPC <= exp_epc;
                cp0_regs_Cause[31] <= exp_bd; //在分支延迟槽发生的异常信号
            end
            cp0_regs_Status[1] <= 1'b1;//EXL置为1，进入例外状态

            cp0_regs_Cause[6:2] <= exp_code; //记录异常原因
            if(hardware_int[5])//属于计时器中断
                cp0_regs_Cause[30] <= 1'b1;
            else
                cp0_regs_Cause[30] <= 1'b0;
        end       
        if(clean_exl & stall) begin //设置异常级别，之后进入内核态同时关中断，交由操作系统决策
            cp0_regs_Status[1] <= 1'b0;
        end
    end
end

endmodule
