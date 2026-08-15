`timescale 1ns/1ns

module tb_jal_jalr;
    reg clk;
    reg rst_n;

    cpu_top dut(
        .clk(clk),
        .rst_n(rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 1'b0;

        #1;
        dut.u_imem.imem[0] = 32'h008002ef; // jal  x5, 8
        dut.u_imem.imem[1] = 32'h00100313; // addi x6, x0, 1 (skipped)
        dut.u_imem.imem[2] = 32'h000083e7; // jalr x7, 0(x1)
        dut.u_imem.imem[3] = 32'h00200313; // addi x6, x0, 2 (skipped)
        dut.u_imem.imem[4] = 32'h00400313; // addi x6, x0, 4 (skipped)
        dut.u_imem.imem[5] = 32'h00300313; // addi x6, x0, 3
        dut.u_regfile.regs[1] = 32'h80000015;

        @(negedge clk);
        rst_n = 1'b1;

        @(posedge clk);
        #1;
        if (dut.pc !== 32'h80000008)
            $fatal(1, "JAL target mismatch: pc=%h", dut.pc);
        if (dut.u_regfile.regs[5] !== 32'h80000004)
            $fatal(1, "JAL link mismatch: x5=%h", dut.u_regfile.regs[5]);

        @(posedge clk);
        #1;
        if (dut.pc !== 32'h80000014)
            $fatal(1, "JALR target mismatch: pc=%h", dut.pc);
        if (dut.u_regfile.regs[7] !== 32'h8000000c)
            $fatal(1, "JALR link mismatch: x7=%h", dut.u_regfile.regs[7]);

        @(posedge clk);
        #1;
        if (dut.u_regfile.regs[6] !== 32'd3)
            $fatal(1, "jumped instruction mismatch: x6=%h", dut.u_regfile.regs[6]);

        $display("PASS: JAL and JALR");
        $finish;
    end
endmodule
