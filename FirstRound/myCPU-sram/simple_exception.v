module exception(
//output
           flush,//异常的停机信号
           cp0_wr_exp,//送CP0异常信号
           cp0_clean_exl,//写往SR[EXL]
           exp_epc,//异常后应记录的EPC
           exp_code,//异常的编号
           exp_bad_vaddr,//发生异常的地址(8)BadVaddr
           cp0_badv_we,
           exception_new_pc,//异常后的新PC
           exp_asid,//ENTRYHi(ASID)与使能
           cp0_exp_asid_we,
//input
           invalid_inst,//未定义指令
           syscall,//系统调用
           break_inst,//break指令
           eret,
           pc_value,//PC现值
           in_delayslot,//在分支延迟槽发生异常
           overflow,//整数运算溢出
           interrupt_flags,//中断信号
           allow_int,//中断使能,{SR(ERL,EXL,IE)==001}
           ebase_in,//(15.1)EBase,产生exception_base
           epc_in,//(14)EPC
           special_int_vec,//(13)Cause(VI)[23],使用特殊中断入口
           boot_exp_vec,
           iaddr_exp_illegal,
           daddr_exp_illegal,
           mem_data_vaddr,
           mem_data_we
    );//启动时异常向量，SR[BEV]==0
input invalid_inst;
input syscall;
input break_inst;
input eret;
input [31:0]pc_value;
input in_delayslot;
input overflow;
input [7:0]interrupt_flags;//中断信号
input allow_int;//中断使能,{SR(ERL,EXL,IE)==001}
input[19:0] ebase_in;
input[31:0] epc_in;
input special_int_vec;//使用特殊中断入口
input boot_exp_vec;//启动时异常向量，SR[BEV]==0
input iaddr_exp_illegal;
input daddr_exp_illegal;
input [31:0] mem_data_vaddr;
input mem_data_we;
//input is_real_inst;

output reg flush;//异常的停机信号
output reg cp0_wr_exp;//送CP0异常信号
output reg cp0_clean_exl;//写往SR[EXL]
output reg[31:0] exp_epc;//异常后应记录的EPC
output reg[4:0] exp_code;//异常的编号
output reg[31:0] exception_new_pc;//异常后的新PC

/*以下为常数0*/
output reg[31:0] exp_bad_vaddr;//发生异常的地址(8)BadVaddr
output reg cp0_badv_we;
output reg[7:0] exp_asid;//ENTRYHi(ASID)与使能
output reg cp0_exp_asid_we;

wire[31:0] exception_base;
assign exception_base = boot_exp_vec ? 32'hBFC00200 : {ebase_in, 12'b0};
always @(*) begin
    //初始化输出的值
    cp0_wr_exp <= 1'b1;//向CP0报告例外发生,需要修改EXL位
    cp0_clean_exl <= 1'b0;//屏蔽其他的中断和例外，陷入内核
    flush <= 1'b1;//如果可识别的情形，给出高电平流水暂停信号，否则保持低电平

    exp_bad_vaddr <= 32'b0;//默认是不登记bad_vaddr和asid
    cp0_badv_we <= 1'b0;

    exp_asid <= 8'b0;
    cp0_exp_asid_we <= 1'b0;

    exp_epc <= in_delayslot ? (pc_value-32'd4) : pc_value;//将PC移入EPC，若延迟槽异常回退一条到分支
    exception_new_pc <= exception_base + 32'h180;//异常后的PC先指向其他异常,默认是32'h(BFC00200+180)
      //exception_new_pc <= pc_value;

    if((~invalid_inst) && allow_int && (interrupt_flags!=8'h0)) begin//使能，且存在中断信号
        if(special_int_vec)
            exception_new_pc <= exception_base + 32'h200;//Cause(IV)为1表示使用特殊中断入口
        exp_code <= 5'h00;//发生Int中断，中断代号为0
        $display("Exception: Interrupt=%x",interrupt_flags);
    end
    //指令地址错，或读数据地址错
    else if(iaddr_exp_illegal) begin//指令出错，记录出错地址，异常代号为4地址加载出错
        exp_bad_vaddr <= pc_value;
        cp0_badv_we <= 1'b1;//记录遇到的错误地址
        exp_code <= 5'h04; //AdEL
        $display("Exception: Instruction address illegal");
    end
    else if(invalid_inst) begin//未定义指令
        exp_code <= 5'h0a;
        $display("Exception: RI");
    end
    else if(overflow) begin//整数运算溢出
        exp_code <= 5'h0c;
        $display("Exception: Ov");
    end
    else if(syscall) begin//Syscall
        exp_code <= 5'h08;
        $display("Exception: Syscall");
    end
    else if(break_inst) begin//Bp
        exp_code <= 5'h09;
        $display("Exception: Breakpoint");
    end
    //写数据地址错
    else if(daddr_exp_illegal) begin//指令TLB错误地址，检查是否是简单重填，记录异常发生地址和地址空间
        exp_bad_vaddr <= mem_data_vaddr;
        cp0_badv_we <= 1'b1;//记录遇到的错误地址
        exp_code <= mem_data_we ? 5'h05 : 5'h04; //AdES : AdEL
        $display("Exception: Data address illegal, WE=%d",mem_data_we);
    end
    else if(eret) begin    //ERET is not a real exception
        exp_code <= 5'h00;//清除异常编号
        cp0_wr_exp <= 1'b0;//清除异常信号
        cp0_clean_exl <= 1'b1;//异常级别SR[EXL]在这条指令后恢复,离开内核态
        exception_new_pc <= epc_in;//恢复到CP0中保存的EPC位置执行
        $display("Pseudo Exception: ERET");
    end
    else begin
        cp0_wr_exp <= 1'b0;//无法识别的异常予以清除
        flush <= 1'b0;//清除异常的停机信号
        exp_code <= 5'h00;//清除无法识别的异常编号
    end
end
endmodule