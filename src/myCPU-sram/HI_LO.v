
/*module hilo_reg(
//output
        rdata,
//input
        clk,
        resetn,
        we,
        wdata
    );
input clk;
input resetn;
input we;
input[63:0] wdata;
output[63:0] rdata;
reg[63:0] hilo;

always @(posedge clk) begin
    if(!resetn) begin
        hilo <= 64'b0;
    end
    else if(we) begin
        hilo <= wdata;
    end
end
assign rdata = we ? wdata : hilo;
endmodule*/

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
/*        $display("hilo = %8h,readdata=%8h"
            ,hilo,rdata);
        $display("mode=%h,rdata1_wb=%8h,alu_r1_wb=%8h,alu_r2_wb=%8h"
            ,mode,rdata1_wb,alu_r1_wb,alu_r2_wb);*/
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
