module regfile(
    //clock and write enable
    input wire clk,
    input wire we,

    //write address and data
    input wire [4:0] waddr,
    input wire [31:0] wdata,

    //read address and data
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
//32-bit register file with 32 registers
    reg [31:0] regs[31:0];

    always @(posedge clk) begin
        if(we==1) begin
            regs[waddr]<=wdata;
        end 
    end
//return the corresponding data based on the address
    assign rdata1=(raddr1==5'd0)?32'd0:regs[raddr1];
    assign rdata2=(raddr2==5'd0)?32'd0:regs[raddr2];


endmodule