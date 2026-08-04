module ALU(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_control,
    
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case(alu_control) 
             4'd0:result=a+b;
             4'd1:result=a-b;
             4'd2:result=a&b;
             4'd3:result=a|b;
             default:result=32'b0;
        endcase
    end
    assign zero=(result==0);
endmodule