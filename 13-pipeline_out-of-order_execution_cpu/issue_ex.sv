module issue_ex(
    input logic clk,
    input logic rst_n,
    input logic flush,

    input logic in_valid,
    input logic [2:0] in_rob_tag,
    input logic [3:0] in_alu_control,
    input logic [31:0] in_rs1_value,
    input logic [31:0] in_rs2_value,

    input logic [2:0] in_kind,
    input logic [31:0] in_pc,
    input logic [31:0] in_imm,
    input logic [2:0] in_funct3,
    input logic [1:0] in_alu_src_a,
    input logic in_alu_src_b,

    output logic out_valid,
    output logic [2:0] out_rob_tag,
    output logic [3:0] out_alu_control,
    output logic [31:0] out_rs1_value,
    output logic [31:0] out_rs2_value,

    output logic [2:0] out_kind,
    output logic [31:0] out_pc,
    output logic [31:0] out_imm,
    output logic [2:0] out_funct3,
    output logic [1:0] out_alu_src_a,
    output logic out_alu_src_b

);
    always_ff@(posedge clk)begin
        if(!rst_n)begin
            out_valid<=0;
            out_alu_control<=4'd0;
            out_rob_tag<=3'd0;
            out_rs1_value<=32'd0;
            out_rs2_value<=32'd0;
            out_kind<=3'd0;
            out_pc<=32'd0;
            out_imm<=32'd0;
            out_funct3<=3'd0;
            out_alu_src_a<=2'd0;
            out_alu_src_b<=0;
        end
        else if(flush)begin
            out_valid<=1'b0;
        end
        else begin
            out_valid<=in_valid;
            out_alu_control<=in_alu_control;
            out_rob_tag<=in_rob_tag;
            out_rs1_value<=in_rs1_value;
            out_rs2_value<=in_rs2_value;
            out_kind<=in_kind;
            out_pc<=in_pc;
            out_imm<=in_imm;
            out_funct3<=in_funct3;
            out_alu_src_a<=in_alu_src_a;
            out_alu_src_b<=in_alu_src_b;
        end

    end

endmodule
