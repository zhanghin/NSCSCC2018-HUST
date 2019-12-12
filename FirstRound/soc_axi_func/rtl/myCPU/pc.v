/*
**  作者：林力韬
**  功能：地址映射
**  原创
*/

module addr_map(
    input   [31:0] addr_in,
    output  [31:0] addr_out
);

    assign addr_out=
    (addr_in[31:30]==2'b11)?
        addr_in :
    (addr_in[31:30]==2'b10)?
        {3'b0,addr_in[28:0]} :
    (addr_in[31]==0)?
        addr_in:0;

endmodule

/*
**  作者：林力韬
**  修改：张鑫
**  功能：程序计数器
**  地址转移逻辑照搬清华大学，但增加了pc地址异常检测
*/
module pc(
    //output
    pc_reg,
    illegal_pc_if,
    //input
    resetn,
    clk,
    pc_en,
    branch_address,
    is_branch,
    is_exception,
    exception_new_pc
);
    parameter PC_INITIAL = 32'hbfc00000;

    input wire resetn;
    input wire clk;
    input wire pc_en;
    input wire[31:0] branch_address;
    input wire is_branch;
    input wire is_exception;
    input wire[31:0] exception_new_pc;

    reg[31:0] pc_next;
    output reg[31:0] pc_reg;
    output illegal_pc_if;

    assign illegal_pc_if = pc_reg[1] | pc_reg[0];

    always @(*) begin
        if (!resetn) begin
          pc_next <= PC_INITIAL;
        end
        else if(pc_en) begin
            if(is_exception) begin
                pc_next <= exception_new_pc;
            end
            else if(is_branch) begin
                pc_next <= branch_address;
            end
            else begin
                pc_next <= pc_reg+32'd4;
            end
        end
        else begin 
            pc_next <= pc_reg;
        end
    end

    always @(posedge clk) begin
        pc_reg <= pc_next;
    end
endmodule