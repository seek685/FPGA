`timescale 1ns/1ps

module tb_pipeline_trace;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [31:0] irom_addr, irom_data;
    logic [31:0] perip_addr, perip_wdata, perip_rdata;
    logic perip_wen;
    logic [1:0] perip_mask;
    logic [31:0] rom [0:4095];
    logic [31:0] dram [0:65535];
    integer i;

    myCPU dut (
        .cpu_clk(clk), .cpu_rst(rst), .irom_addr(irom_addr), .irom_data(irom_data),
        .perip_addr(perip_addr), .perip_wen(perip_wen), .perip_mask(perip_mask),
        .perip_wdata(perip_wdata), .perip_rdata(perip_rdata)
    );

    assign irom_data = rom[irom_addr[13:2]];
    assign perip_rdata = (perip_addr >= 32'h8010_0000 && perip_addr < 32'h8014_0000)
                       ? dram[perip_addr[17:2]] : 32'd0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst && (dut.pc[13:0] >= 14'h0d00)) begin
            $display("TRACE t=%0t pc=%08h ifid_pc=%08h idex_pc=%08h ifid_i=%08h idex_v=%b exmem_v=%b mwb_v=%b stall=%b flush=%b br=%b j=%b rs1=%0d=%08h rs2=%0d=%08h a=%08h b=%08h alu=%08h ra=%08h count=%08h",
                $time, dut.pc, dut.if_id_pc, dut.id_ex_pc, dut.if_id_instr, dut.id_ex_valid,
                dut.ex_mem_valid, dut.mem_wb_valid, dut.stall, dut.flush, dut.id_ex_branch,
                dut.id_ex_jump, dut.id_ex_rs1, dut.forwarded_rs1_value, dut.id_ex_rs2,
                dut.forwarded_rs2_value, dut.a, dut.b, dut.alu_result, dut.u_regfile.regs[1], dram[0]);
        end
        if (!rst && perip_wen && perip_addr == 32'h8010_0000)
            $display("COUNT t=%0t data=%08h", $time, perip_wdata);
        if (!rst && perip_wen && (perip_addr >= 32'h8020_0000))
            $display("MMIO t=%0t addr=%08h data=%08h mask=%b", $time, perip_addr, perip_wdata, perip_mask);
    end

    initial begin
        for (i = 0; i < 4096; i = i + 1) rom[i] = 32'h00000013;
        for (i = 0; i < 65536; i = i + 1) dram[i] = 32'd0;
        $readmemb("D:/_small_eyes/JYD2025_Contest-rv32i/digital_twin.gen/sources_1/ip/IROM/IROM.mif", rom);
        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (3000) @(posedge clk);
        $finish;
    end
endmodule
