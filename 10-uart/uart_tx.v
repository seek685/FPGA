module uart_tx#(
    parameter CLK_FREQ=50_000_000,
    parameter BAUD=1_000_000
)
(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_vaild,
    
    output wire tx_busy,
    output reg txd

);
    localparam baud_div=CLK_FREQ/BAUD-1;
    localparam baud_cnt_width=(baud_div<1)?1:$clog2(baud_div+1);

    reg state;// uart busy or not
    reg [baud_cnt_width-1:0] baud_cnt;
    reg [3:0] bit_cnt;
    reg [9:0] tx_shift;//{stop,data[7:0],start}

    assign tx_busy=state;
    always@(posedge clk or negedge rst_n) begin
        if(rst_n==0)begin
            state<=0;
            baud_cnt<=0;
            bit_cnt<=4'd0;
            txd<=1;
        end
        else begin 
            if(state==1) begin
                baud_cnt<=baud_cnt+1;
                if(baud_cnt==baud_div) begin
                    baud_cnt<=0;
                    tx_shift<={1'b1,tx_shift[9:1]};//tx_shift>>1 and add 1 to high
                    txd<=tx_shift[1];//tx_shift not upgrade
                    bit_cnt<=bit_cnt+1;
                    if(bit_cnt==9) begin
                        bit_cnt<=0;
                        state<=0;
                    end
                end
            end else begin
                txd<=1;
                if(tx_vaild==1)begin //instantly rec txdata
                    tx_shift<={1'b1,tx_data,1'b0};
                    state<=1;
                    txd<=0;
                end
            end 
        end
    end
endmodule
