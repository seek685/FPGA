module ALU(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_control,
    
    output reg [31:0] alu_result,
    output wire zero
);
    always @(*) begin
        case(alu_control) 
             4'd0:alu_result=a+b;
             4'd1:alu_result=a-b;
             4'd2:alu_result=a&b;
             4'd3:alu_result=a|b;
             default:alu_result=32'b0;
        endcase
    end
    assign zero=(alu_result==0);
endmodule