module dmem(
    input wire mem_write,
    input wire mem_read,
    input wire clk,
    input wire [31:0] mem_wdata,
    input wire [31:0] addr,

    output reg [31:0] read_data
);
    reg [31:0] dmem [0:255];
    always @(posedge clk) begin
        if(mem_write)
            dmem[(addr)>>2]<=mem_wdata;
            //base address is 0x0 not 0x8000_0000
    end
    always @(*) begin
          if(mem_read)
            read_data=dmem[(addr)>>2];
        else read_data=32'd0;
    end
    initial begin
    $readmemh("dmem_data.hex", dmem);
end
endmodule