module ALU(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_control,
    
    output reg [31:0] alu_result
   // output wire zero
);
    //R'b=rs2  I'b=imm
    //I:alu_src=1,b=imm   R:alu_src=0,b=rs2
    always @(*) begin
        case(alu_control) 
             4'b0000:alu_result=a+b;
             4'b0001:alu_result=a-b;
             4'b0010:alu_result=a&b;
             4'b0011:alu_result=a|b;
             //slt sltu xor sll srl sra
             4'b0100:alu_result=($signed(a)<$signed(b))?32'd1:32'd0;
             4'b0101:alu_result=a<b?32'd1:32'd0;//default unsigned
             4'b0110:alu_result=a^b;
             4'b0111:alu_result=a<<b[4:0];
             4'b1000:alu_result=a>>b[4:0];//high insert 0 bit
             4'b1001:alu_result=$signed(a)>>>b[4:0];//high insert signed bit
             default:alu_result=32'b0;
        endcase
    end //sra :>>>   b[4:0]: move always deal with unsigned
   // assign zero=(alu_result==0);
endmodule