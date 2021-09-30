/*
**  作者：林力韬
**  功能：通用寄存器组
**  照搬清华大学
*/
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


/*
**  作者：林力韬
**  修改：张鑫
**  功能：HILO寄存器
**  原本照搬清华，进过修改后基本上没有参考的部分
*/
module hilo_reg(
//output
    rdata,
//input
    clk,
    resetn,
    mode,
    rdata1_wb,
    alu_r1_wb,
    alu_r2_wb
);
    input clk;
    input resetn;
    input [1:0]mode;
    input [31:0]rdata1_wb;
    input [31:0]alu_r1_wb;
    input [31:0]alu_r2_wb;

    output reg[63:0]rdata;

    reg[63:0] hilo;

    always @(posedge clk) begin
        if(!resetn) begin
            hilo <= 64'b0;
        end
        else begin
            case(mode)
                2'b11: begin
                    hilo <= { alu_r2_wb,alu_r1_wb };
                end // 2'b00:
                2'b01: begin
                    hilo[31:0] <= rdata1_wb;
                end // 2'b01:
                2'b10: begin
                    hilo[63:32] <= rdata1_wb;
                end // 2'b10:
                default: begin
                    hilo <= hilo;
                end // default:
            endcase // mode
        end
    end

    always @(*) begin
        case(mode)
            2'b11: begin
                rdata <= { alu_r2_wb,alu_r1_wb };
            end // 2'b00:
            2'b01: begin
                rdata <= { hilo[63:32],rdata1_wb };
            end // 2'b01:
            2'b10: begin
                rdata <= { rdata1_wb,hilo[31:0] };
            end // 2'b10:
            default: begin
                rdata <= hilo;
            end // default:
        endcase // mode
    end // always @(*)

endmodule