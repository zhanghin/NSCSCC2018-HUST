module regs(
//output
    rdata1, //[4:0]读寄存器的地址123
    rdata2,
    //rdata3,
//input
    clk, //上升沿驱动
    rst, //低电平复位
    we, //1b 写使能信号
    waddr, //[4:0]写寄存器的地址
    wdata, //[31:0]写寄存器的数据
    raddr1, //[4:0]读寄存器的结果123
    raddr2
);
    input wire clk;
    input wire rst;
    input wire we;
    input wire[4:0] waddr;
    input wire[31:0] wdata;

    input wire[4:0] raddr1;
    output reg[31:0] rdata1;

    input wire[4:0] raddr2;
    output reg[31:0] rdata2;

    reg[31:0] registers[0:31];

    always @(posedge clk) begin
        if(!rst) begin //复位所有的寄存器
            registers[0] <= 32'b0;
            registers[1] <= 32'b0;
            registers[2] <= 32'b0;
            registers[3] <= 32'b0;
            registers[4] <= 32'b0;
            registers[5] <= 32'b0;
            registers[6] <= 32'b0;
            registers[7] <= 32'b0;
            registers[8] <= 32'b0;
            registers[9] <= 32'b0;
            registers[10] <= 32'b0;
            registers[11] <= 32'b0;
            registers[12] <= 32'b0;
            registers[13] <= 32'b0;
            registers[14] <= 32'b0;
            registers[15] <= 32'b0;
            registers[16] <= 32'b0;
            registers[17] <= 32'b0;
            registers[18] <= 32'b0;
            registers[19] <= 32'b0;
            registers[20] <= 32'b0;
            registers[21] <= 32'b0;
            registers[22] <= 32'b0;
            registers[23] <= 32'b0;
            registers[24] <= 32'b0;
            registers[25] <= 32'b0;
            registers[26] <= 32'b0;
            registers[27] <= 32'b0;
            registers[28] <= 32'b0;
            registers[29] <= 32'b0;
            registers[30] <= 32'b0;
            registers[31] <= 32'b0;
        end
        else if(we && waddr!=5'h0) begin //写使能1且写地址非0寄存器，将数据写入reg[0] 
            registers[waddr] <= wdata;
/*            $display("$ 0=%8h $ 1=%8h $ 2=%8h $ 3=%8h $ 4=%8h $ 5=%8h $ 6=%8h $ 7=%8h"
                ,registers[0],registers[1],registers[2],registers[3]
                ,registers[4],registers[5],registers[6],registers[7]);
            $display("$ 8=%8h $ 9=%8h $10=%8h $11=%8h $12=%8h $13=%8h $14=%8h $15=%8h "
                ,registers[8],registers[9],registers[10],registers[11]
                ,registers[12],registers[13],registers[14],registers[15]);
            $display("$16=%8h $17=%8h $18=%8h $19=%8h $20=%8h $21=%8h $22=%8h $23=%8h "
                ,registers[16],registers[17],registers[18],registers[19]
                ,registers[20],registers[21],registers[22],registers[23]);
            $display("$24=%8h $25=%8h $26=%8h $27=%8h $28=%8h $29=%8h $30=%8h $31=%8h "
                ,registers[24],registers[25],registers[26],registers[27]
                ,registers[28],registers[29],registers[30],registers[31]);*/
        end
    end

    always @(*) begin
        if(raddr1 == 32'b0) //读地址为0，直接读常数
            rdata1 <= 32'b0;
        else if(raddr1 == waddr && we) //寄存器写入的数据可以立即读出
            rdata1 <= wdata;
        else
            rdata1 <= registers[raddr1]; //读地址1的寄存器值
    end

    always @(*) begin
        if(raddr2 == 32'b0)
            rdata2 <= 32'b0;
        else if(raddr2 == waddr && we)
            rdata2 <= wdata;
        else
            rdata2 <= registers[raddr2]; //读地址2的寄存器值
    end

endmodule