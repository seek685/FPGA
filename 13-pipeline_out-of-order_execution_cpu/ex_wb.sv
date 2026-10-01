module ex_wb(
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    input logic [2:0] in_rob_tag,
    input logic [31:0] in_value,

    output logic out_valid,
    output logic [2:0] out_rob_tag,
    output logic [31:0] out_value

);

    always_ff@(posedge clk)begin
        if(!rst_n)begin
            out_valid<=0;
            out_rob_tag<=3'd0;
            out_value<=32'd0;
        end
        else begin
            out_valid<=in_valid;
            out_rob_tag<=in_rob_tag;
            out_value<=in_value;
        end
    end

endmodule