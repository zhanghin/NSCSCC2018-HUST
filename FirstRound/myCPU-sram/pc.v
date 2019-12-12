
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

    always @(*) begin
        if (!resetn) begin
          pc_next <= PC_INITIAL;
        end
        else if(pc_en) begin
            if(is_exception) begin
                pc_next <= exception_new_pc;
            end
            else if(is_branch) begin
                pc_next <= branch_address;//???????
            end
            else begin
                pc_next <= pc_reg+32'd4;
            end
        end
        else begin 
            pc_next <= pc_reg;
        end
    end

    assign illegal_pc_if = pc_reg[1] | pc_reg[0];

    always @(posedge clk) begin
        pc_reg <= pc_next;
        
/*        $display("is_exception=%h,is_branch=%h,exception_new_pc=%8h"
          ,is_exception,is_branch,exception_new_pc);*/
    end
endmodule

/*
module ins_sram_adapter#()(
read,
sram_stall
);
wire input  read;
wire output sram_stall;
reg dirty;
assign sram_stall = read && ~dirty;
always(@posedge clk)begin
if(!rst)begin
dirty<=0;
end
else if(read==1)begin
if(dirty==0)begin
dirty<=1; //如果当前周期访问停机，下一周期解除停机
end else 
end
if(dirty==1) begin//任意时刻，dirty恢复到0接受访问请求
dirty<=0;
end
end
endmodule
*/
