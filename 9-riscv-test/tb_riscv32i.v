`timescale 1ns/1ns

module tb_riscv32i;
    reg clk;
    reg rst_n;
    initial clk=0;
    always #5 clk=~clk;
    integer cycles;
    initial cycles=0;
    always @(posedge clk) cycles=cycles+1;

    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        rst_n=1'b0;
        #1;
        rst_n=1'b1;
        while (cycles < 200000) #10;     
        $display("TIMEOUT - no tohost write, CPU likely hung");
        $finish;
    end

    always @(posedge clk) begin
        if(dut.u_dmem.mem_write&&dut.u_dmem.addr==32'h0000_1000) begin
            if(dut.u_dmem.mem_wdata==32'd1) begin
                $display("%d cycles PASS",cycles);
                $finish;
            end
            else begin
                $display("%d cycles Fail ",cycles);
            end
        end
    end
endmodule