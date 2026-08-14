module dmem(
    input wire mem_write,
    input wire mem_read,
    input wire clk,
    input wire [31:0] mem_wdata,
    input wire [31:0] addr,
    input wire [2:0] funct3,
    
    output reg [31:0] read_data
);
    wire [31:0] word;
    wire [7:0] selected_byte;
    wire [15:0] selected_halfword;
    reg [31:0] dmem [0:4095];//16KB
    always @(posedge clk) begin
        if(mem_write) begin
            case(funct3)
                //keep dmem high data
                3'b000:case(addr[1:0])
                    2'b00:dmem[(addr)>>2][7:0]<=mem_wdata[7:0];//SB
                    2'b01:dmem[(addr)>>2][15:8]<=mem_wdata[7:0];
                    2'b10:dmem[(addr)>>2][23:16]<=mem_wdata[7:0];
                    2'b11:dmem[(addr)>>2][31:24]<=mem_wdata[7:0];
                endcase
                3'b001:case(addr[1])
                        1'b0:dmem[(addr)>>2][15:0]<=mem_wdata[15:0];//SH
                        1'b1:dmem[(addr)>>2][31:16]<=mem_wdata[15:0];
                endcase
                3'b010:dmem[(addr)>>2]<=mem_wdata;//SW
                //base address is 0x0 not 0x8000_0000
            endcase
        end
    end
    assign word=dmem[addr>>2];
    assign selected_byte=word>>{addr[1:0],3'b000};
    assign selected_halfword=addr[1]?word[31:16]:word[15:0];
    always @(*) begin
        if(mem_read) begin
            case(funct3)
                3'b000:read_data={{24{selected_byte[7]}},selected_byte}; //LB
                3'b001:read_data={{16{selected_halfword[15]}},selected_halfword}; //LH
                3'b010:read_data=word;//LW
                3'b100:read_data={24'h000000,selected_byte}; //LBU
                3'b101:read_data={16'h0000,selected_halfword}; //LHU
                default:read_data=0;
            endcase
        end
        else read_data=32'd0;
    end
    initial begin
        $readmemh("dmem_data.hex", dmem);
    end
endmodule
