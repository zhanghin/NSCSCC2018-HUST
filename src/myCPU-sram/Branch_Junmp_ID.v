//b指令需要加4，而j指令不需要

module Branch_Jump_ID(
//input
    bj_type_ID,
    num_a_ID,
    num_b_ID,
    imm_b_ID,
    imm_j_ID,
    JR_addr_ID,
    PC_ID,
//output
    Branch_Jump,
    BJ_address
);
`define BRANCH_BEQ 32'd1
`define BRANCH_BNE 32'd2
`define BRANCH_BGEZ 32'd4
`define BRANCH_BGTZ 32'd8
`define BRANCH_BLEZ 32'd16
`define BRANCH_BLTZ 32'd32
`define BRANCH_BLTZAL 32'd64
`define BRANCH_BGEZAL 32'd128
`define J_JAL 32'd256
`define JALR_JR 32'd512
    input wire [9:0]bj_type_ID;
    input wire [31:0]num_a_ID;
    input wire [31:0]num_b_ID;
    input wire [31:0]imm_b_ID;
    input wire [25:0]imm_j_ID;
    input wire [31:0]JR_addr_ID;
    input wire [31:0]PC_ID;
    output reg Branch_Jump;
    output reg [31:0]BJ_address;

    always@(*)begin
      case (bj_type_ID)
        `BRANCH_BEQ:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID == num_b_ID) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end 
        `BRANCH_BNE:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID != num_b_ID) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BGEZ:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID[31]==0||num_a_ID== 0) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BLEZ:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID[31]==1||num_a_ID== 0) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BGTZ:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if( num_a_ID[31]==0 && (num_a_ID != 0)) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BLTZ:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID[31]==1&&num_a_ID > 0) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BLTZAL:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID[31]==1&&num_a_ID > 0) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `BRANCH_BGEZAL:begin
            BJ_address <= (imm_b_ID << 2) + PC_ID + 32'd4;
            if(num_a_ID[31]==0||num_a_ID == 0) begin
                Branch_Jump <= 1;
            end
            else begin
                Branch_Jump <= 0;
            end
        end
        `J_JAL:begin
            BJ_address[1:0] <= 2'b0;
            BJ_address[31:28] <= PC_ID[31:28];
            BJ_address[27:2] <= imm_j_ID[25:0];
            Branch_Jump <= 1;
        end
        `JALR_JR:begin
            BJ_address <= JR_addr_ID;
            Branch_Jump <= 1;
        end
        default: begin
           BJ_address <= PC_ID + 32'd4;
           Branch_Jump <= 0;
        end
      endcase
    end
endmodule