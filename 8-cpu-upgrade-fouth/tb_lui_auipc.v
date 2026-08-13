`timescale 1ns/1ns
module tb_lui_auipc;
    reg clk;
    reg rst_n;
    cpu_top dut(
        .clk(clk),
        .rst_n
    );
    initial clk=0;
    always #5 clk=~clk;

    initial begin
        rst_n=0;

        #1;
        dut.u_imem.imem[0]=32'h123450B7;//lui x1,0x12345
        dut.u_imem.imem[1]=32'h7EDCB117;//auipc x2,0x7edcb

        @(negedge clk);
        rst_n=1;

        @(posedge clk);
        #1;
        if(dut.u_regfile.regs[1]!==32'h1234_5000)
            $fatal(1,"lui target mismatch:x1=%h ",dut.u_regfile.regs[1]);

        @(posedge clk);
        #1;
        if(dut.pc!==32'h8000_0008)
            $fatal(1,"pc target mismatch:pc=%h",dut.pc);
        if(dut.u_regfile.regs[2]!==32'hFEDC_B004)
            $fatal(1,"auipc target mismatch:x2=%h",dut.u_regfile.regs[2]);

        $display("PASS: auipc and lui");
        $finish;
    end

endmodule