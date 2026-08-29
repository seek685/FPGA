`timescale 1ns/1ps

module tb_student_actual;
    logic cpu_clk = 1'b0;
    logic cnt_clk = 1'b0;
    logic rst = 1'b1;
    logic [7:0] virtual_key = 8'd0;
    logic [63:0] virtual_sw = 64'd0;
    wire [31:0] virtual_led;
    wire [39:0] virtual_seg;

    student_top dut (
        .w_cpu_clk(cpu_clk), .w_clk_50Mhz(cnt_clk), .w_clk_rst(rst),
        .virtual_key(virtual_key), .virtual_sw(virtual_sw),
        .virtual_led(virtual_led), .virtual_seg(virtual_seg)
    );

    always #5 cpu_clk = ~cpu_clk;
    always #10 cnt_clk = ~cnt_clk;

    always @(posedge cpu_clk) begin
        if (!rst && dut.Core_cpu.perip_wen) begin
            $display("BUS t=%0t addr=%08h mask=%b data=%08h rdata=%08h led=%08h seg=%010h",
                $time, dut.Core_cpu.perip_addr, dut.Core_cpu.perip_mask,
                dut.Core_cpu.perip_wdata, dut.Core_cpu.perip_rdata,
                virtual_led, virtual_seg);
        end
        if (!rst && dut.Core_cpu.mem_wb_valid && dut.Core_cpu.mem_wb_reg_write)
            $display("WB  t=%0t rd=x%0d data=%08h pc=%08h",
                $time, dut.Core_cpu.mem_wb_rd, dut.Core_cpu.write_back,
                dut.Core_cpu.pc);
    end

    initial begin
        repeat (4) @(posedge cpu_clk);
        rst = 1'b0;
        repeat (200000) @(posedge cpu_clk);
        $display("FINAL led=%08h seg=%010h pc=%08h count=%08h",
            virtual_led, virtual_seg, dut.Core_cpu.pc,
            dut.bridge_inst.dram_driver_inst.Mem_DRAM.inst.ram_data[0]);
        $finish;
    end
endmodule
