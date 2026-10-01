module issue_ex(
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    input logic [2:0] in_rob_tag,
    input logic [3:0] in_alu_control,
    input logic [31:0] in_rs1_value,
    input logic [31:0] in_rs2_value,

    output logic out_valid,
    output logic [2:0] out_rob_tag,
    output logic [3:0] out_alu_control,
    output logic [31:0] out_rs1_value,
    output logic [31:0] out_rs2_value

);
    always_ff@(posedge clk)begin
        if(!rst_n)begin
            out_valid<=0;
            out_alu_control<=4'd0;
            out_rob_tag<=3'd0;
            out_rs1_value<=32'd0;
            out_rs2_value<=32'd0;
        end
        else begin
            out_valid<=in_valid;
            out_alu_control<=in_alu_control;
            out_rob_tag<=in_rob_tag;
            out_rs1_value<=in_rs1_value;
            out_rs2_value<=in_rs2_value; 
        end

    end

endmodule