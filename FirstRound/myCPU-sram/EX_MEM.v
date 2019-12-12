//选择模块尽可能早选择，少往后传数据和信号，需要优化
module EX_MEM(
    //input
    clk,
    stall,
    rset,

    control_signal_in,
    registerW_in,
    value_ALU_in,
    value_ALU2_in,
    rdata1_in,
    rdata2_in,
    PC_in,
    sel_in,
    HILO_in,
    cp0_data_in,
    cp0_rw_reg_in,
    overflow_in,
    illegal_pc_in,
    in_delayslot_in,
    is_bj_in,
    bj_address_in,
    //ouput
    control_signal_out,
    registerW_out,
    value_ALU_out,
    value_ALU2_out,
    rdata1_out,
    rdata2_out,
    PC_out,
    sel_out,
    HILO_out,
    cp0_data_out,
    cp0_rw_reg_out,
    overflow_out,
    illegal_pc_out,
    in_delayslot_out,
    is_bj_out,
    bj_address_out
);
    input clk,stall,rset;
    input [60:0]control_signal_in;
    input [4:0]registerW_in;
    input [31:0]value_ALU_in;
    input [31:0]value_ALU2_in;
    input [31:0]rdata1_in,rdata2_in;
    input [31:0]PC_in;
    input [2:0]sel_in;
    input [63:0]HILO_in;
    input [31:0]cp0_data_in;
    input [4:0]cp0_rw_reg_in;
    input overflow_in;
    input illegal_pc_in;
    input in_delayslot_in;
    input is_bj_in;
    input [31:0]bj_address_in;

    output reg [60:0]control_signal_out;
    output reg [4:0]registerW_out;
    output reg [31:0]value_ALU_out;
    output reg [31:0]value_ALU2_out;
    output reg [31:0]rdata1_out,rdata2_out;
    output reg [31:0]PC_out;
    output reg [2:0]sel_out;
    output reg [63:0]HILO_out;
    output reg [31:0]cp0_data_out;
    output reg [4:0]cp0_rw_reg_out;
    output reg overflow_out;
    output reg illegal_pc_out;
    output reg in_delayslot_out;
    output reg is_bj_out;
    output reg [31:0]bj_address_out;

    always@(posedge clk)begin
      if (!rset) begin
        control_signal_out <= 0;
        registerW_out <= 0;
        value_ALU_out <= 0;
        value_ALU2_out <= 0;
        rdata1_out <= 0;
        rdata2_out <= 0;
        PC_out <= 0;
        sel_out <= 0;
        HILO_out <= 0;
        cp0_data_out <= 0;
        cp0_rw_reg_out <= 0;
        overflow_out <= 0;
        illegal_pc_out <= 0;
        in_delayslot_out <= 0;
        is_bj_out <= 0;
        bj_address_out <= 0;
      end else if (!stall) begin
        control_signal_out <= control_signal_out;
        registerW_out <= registerW_out;
        value_ALU_out <= value_ALU_out;
        value_ALU2_out <= value_ALU2_out;
        rdata1_out <= rdata1_out;
        rdata2_out <= rdata2_out;
        PC_out <= PC_out;   
        sel_out <= sel_out; 
        HILO_out <= HILO_out;
        cp0_data_out <= cp0_data_out;
        cp0_rw_reg_out <= cp0_rw_reg_out;
        overflow_out <= overflow_out;
        illegal_pc_out <= illegal_pc_out;
        in_delayslot_out <= in_delayslot_out;
        is_bj_out <= is_bj_out;
        bj_address_out <= bj_address_out;
      end else begin
        control_signal_out <= control_signal_in;
        registerW_out <= registerW_in;
        value_ALU_out <= value_ALU_in;
        value_ALU2_out <= value_ALU2_in;
        rdata1_out <= rdata1_in;
        rdata2_out <= rdata2_in;
        PC_out <= PC_in; 
        sel_out <= sel_in; 
        HILO_out <= HILO_in;
        cp0_data_out <= cp0_data_in;
        cp0_rw_reg_out <= cp0_rw_reg_in;
        overflow_out <= overflow_in;
        illegal_pc_out <= illegal_pc_in;
        in_delayslot_out <= in_delayslot_in;
        is_bj_out <= is_bj_in;
        bj_address_out <= bj_address_in;
      end 
    end
endmodule