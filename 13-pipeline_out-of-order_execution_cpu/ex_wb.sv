module ex_wb(
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    input logic [2:0] in_rob_tag,
    input logic [31:0] in_value,
    input logic in_result_valid,
    input logic [2:0] in_kind,
    input logic in_actual_taken,
    input logic [31:0] in_actual_target,
    input logic [31:0] in_actual_next_pc,

    output logic out_valid,
    output logic [2:0] out_rob_tag,
    output logic [31:0] out_value,
    output logic out_result_valid,
    output logic [2:0] out_kind,
    output logic out_actual_taken,
    output logic [31:0] out_actual_target,
    output logic [31:0] out_actual_next_pc

);

    always_ff@(posedge clk)begin
        if(!rst_n)begin
            out_valid<=0;
            out_rob_tag<=3'd0;
            out_value<=32'd0;
            out_result_valid<=0;
            out_kind<=3'd0;
            out_actual_taken<=0;
            out_actual_target<=32'd0;
            out_actual_next_pc<=32'd0;
        end
        else begin
            out_valid<=in_valid;
            out_rob_tag<=in_rob_tag;
            out_value<=in_value;
            out_result_valid<=in_valid&&in_result_valid;
            out_kind<=in_kind;
            out_actual_taken<=in_actual_taken;
            out_actual_target<=in_actual_target;
            out_actual_next_pc<=in_actual_next_pc;
        end
    end

endmodule
