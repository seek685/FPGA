`timescale 1ns/1ns
module tb_cpu_top;
    reg clk;
    reg rst_n;
    initial clk=0;
    always #5 clk=~clk;
    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n)
    );
    initial begin
        rst_n=0;
        repeat(3) @(posedge clk);
        #1 rst_n=1;
        #3000;
    end
endmodule