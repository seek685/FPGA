`timescale 1ns/1ns
module tb_beq;
    reg clk;
    reg rst_n;
    integer errors;

    initial clk = 0;
    always #5 clk = ~clk;

    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n)
    );

    always @(posedge clk)
        $display("t=%0t pc=%h instr=%h", $time, dut.pc, dut.instr);

    initial begin
        rst_n = 0;
        errors = 0;
        repeat(3) @(posedge clk);
        #1 rst_n = 1;
        repeat(12) @(posedge clk);

        if ($test$plusargs("CASE2")) begin
            // 用例2: beq 应跳转 —— dmem[2] 保持哨兵 0, dmem[3] 被写 7
            if (dut.u_dmem.dmem[2] !== 32'd0) begin
                $display("FAIL: dmem[2]=%h, expected 00000000", dut.u_dmem.dmem[2]);
                errors = errors + 1;
            end
            if (dut.u_dmem.dmem[3] !== 32'd7) begin
                $display("FAIL: dmem[3]=%h, expected 00000007", dut.u_dmem.dmem[3]);
                errors = errors + 1;
            end
        end else begin
            // 用例1: beq 应不跳 —— sw 被执行, dmem[2] 被写 7
            if (dut.u_dmem.dmem[2] !== 32'd7) begin
                $display("FAIL: dmem[2]=%h, expected 00000007", dut.u_dmem.dmem[2]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("ALL PASS");
        $finish;
    end
endmodule
