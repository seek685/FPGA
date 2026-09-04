module if_id(
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,
    input  logic        stall,

    input  logic        in_valid,
    input  logic [31:0] in_pc,
    input  logic [31:0] in_pc4,
    input  logic [31:0] in_instr,

    output logic        out_valid,
    output logic [31:0] out_pc,
    output logic [31:0] out_pc4,
    output logic [31:0] out_instr
);
    always_ff@(posedge clk) begin
        if(rst==0) begin
            out_valid<=1'b0;
            out_pc<=32'd0;
            out_pc4<=32'd0;
            out_instr<=32'd0;
        end
        else if(flush==1)begin
            out_valid<=1'b0;
            out_pc<=32'd0;
            out_pc4<=32'd0;
            out_instr<=32'd0;
        end
        else if(stall==1)begin
            //hold current state
        end 
        else begin
            out_valid<=in_valid;
            out_pc<=in_pc;
            out_pc4<=in_pc4;
            out_instr<=in_instr;
        end
    end

endmodule