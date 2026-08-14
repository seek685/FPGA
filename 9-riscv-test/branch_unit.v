module branch_unit(
    input wire [31:0] rdata1,
    input wire [31:0] rdata2,
    input wire [2:0] funct3,
    
    output reg branch_1
);
    always @(*) begin
        case(funct3)
            3'b000:branch_1=(rdata1==rdata2);//beq
            3'b001:branch_1=(rdata1!=rdata2);//bne
            3'b100:branch_1=($signed(rdata1)<$signed(rdata2));//blt
            3'b101:branch_1=($signed(rdata1)>=$signed(rdata2));//bge
            3'b110:branch_1=(rdata1<rdata2);//bltu
            3'b111:branch_1=(rdata1>=rdata2);//bgeu
            default:branch_1=1'b0;
        endcase
    end

endmodule