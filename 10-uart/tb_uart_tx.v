`timescale 1ns/1ns
module tb_uart_tx;
    reg clk;
    reg rst_n;
    reg [7:0] tx_data;
    reg tx_vaild;

    wire txd;

    parameter CLK_FREQ=50_000_000;
    parameter BAUD=1_000_000;
    parameter CLK_PERIOD_NS=1_000_000_000/CLK_FREQ;//s-ns
    integer i=0;
    integer errors=0;

    reg [7:0] rec_buf;
    parameter baud_div=CLK_FREQ/BAUD-1;
    parameter bit_period=(baud_div+1)*CLK_PERIOD_NS;//constant time
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    )u_uart_tx(
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_vaild(tx_vaild),
        .txd(txd)
    );

    initial clk=0;
    always#(CLK_PERIOD_NS/2) clk=~clk;
    initial tx_vaild=0;
    initial begin
        rst_n=0;
        repeat(2) @(posedge clk);
        rst_n=1;

        @(negedge clk);
        tx_data=8'h00;
        tx_vaild=1;
        @(negedge clk);
        tx_vaild=0;
        rec(baud_div);
        #(bit_period);
        if(txd==1)$display("check right");
        else begin
            $display("check fail");
            errors=errors+1;
        end
        if(rec_buf==tx_data)$display("1 PASS");
        else errors=errors+1;
        #(bit_period/2);
        
        @(negedge clk);
        tx_data=8'hFF;
        tx_vaild=1;
        @(negedge clk);
        tx_vaild=0;
        rec(baud_div);
        #(bit_period);
        if(txd==1)$display("check right");
        else begin
            $display("check fail");
            errors=errors+1;
        end
        if(rec_buf==tx_data)$display("2 PASS");
        else errors=errors+1;
        #(bit_period/2);

        @(negedge clk);
        tx_data=8'h55;
        tx_vaild=1;
        @(negedge clk);
        tx_vaild=0;
        rec(baud_div);
        #(bit_period);
        if(txd==1)$display("check right");
        else begin
            $display("check fail");
            errors=errors+1;
        end
        if(rec_buf==tx_data)$display("3 PASS");
        else errors=errors+1;
        #(bit_period/2);

        @(negedge clk);
        tx_data=8'hA5;
        tx_vaild=1;
        @(negedge clk);
        tx_vaild=0;
        rec(baud_div);
        #(bit_period);
        
        if(txd==1)$display("check right");
        else begin
            $display("check fail");
            errors=errors+1;
        end
        if(rec_buf==tx_data)$display("4 PASS");
        else errors=errors+1;

        if(errors==0)$display("ALL PASS");
        else $display("%d Errors",errors);

        $finish;
    end
    task rec;
        input [9:0]div;
        begin
            for(i=0;i<8;i=i+1)begin
                if(i==0)#((div+1)*CLK_PERIOD_NS*1.5);
                else #((div+1)*CLK_PERIOD_NS);
                rec_buf={txd,rec_buf[7:1]};//>>
            end
        end
    endtask

endmodule
