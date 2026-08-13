module pc(
    input wire clk,
    input wire rst_n,
    input wire [31:0] next_pc,
    output reg [31:0] pc
);

always @(posedge clk or negedge rst_n) begin
    if(rst_n==0) 
        pc<=32'h8000_0000;
    else pc<=next_pc;
end
endmodule