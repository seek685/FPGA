`timescale 1ns/1ps

module tb_pipeline_debug;
    logic        clk;
    logic        rst;
    logic [31:0] irom_addr;
    logic [31:0] irom_data;
    logic [31:0] perip_addr;
    logic        perip_wen;
    logic [1:0]  perip_mask;
    logic [31:0] perip_wdata;
    logic [31:0] perip_rdata;

    logic [31:0] rom [0:4095];
    logic [31:0] dram [0:65535];
    integer i;

    myCPU dut (
        .cpu_clk    (clk),
        .cpu_rst    (rst),
        .irom_addr  (irom_addr),
        .irom_data  (irom_data),
        .perip_addr (perip_addr),
        .perip_wen  (perip_wen),
        .perip_mask (perip_mask),
        .perip_wdata(perip_wdata),
        .perip_rdata(perip_rdata)
    );

    assign irom_data = rom[irom_addr[13:2]];
    assign perip_rdata = (perip_addr >= 32'h8010_0000 && perip_addr < 32'h8014_0000)
                       ? dram[perip_addr[17:2]]
                       : 32'h0;

    always @(posedge clk) begin
        if (perip_wen && perip_addr >= 32'h8010_0000 && perip_addr < 32'h8014_0000) begin
            dram[perip_addr[17:2]] <= perip_wdata;
            $display("STORE t=%0t addr=%08h mask=%0d data=%08h", $time, perip_addr, perip_mask, perip_wdata);
        end
        if (perip_wen && perip_addr >= 32'h8020_0000) begin
            $display("MMIO  t=%0t addr=%08h mask=%0d data=%08h", $time, perip_addr, perip_mask, perip_wdata);
        end
    end

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        for (i = 0; i < 4096; i = i + 1) rom[i] = 32'h00000013;
        for (i = 0; i < 65536; i = i + 1) dram[i] = 32'd0;
        dram[3] = 32'h1234_abcd;
        dram[4] = 32'h5566_7788;
        dram[7] = 32'hff00_00ff;
        $readmemb("D:/_small_eyes/JYD2025_Contest-rv32i/digital_twin.gen/sources_1/ip/IROM/IROM.mif", rom);
        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (200000) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && dut.mem_wb_valid && dut.mem_wb_reg_write)
            $display("WB    t=%0t rd=x%0d data=%08h", $time, dut.mem_wb_rd, dut.write_back);
    end
endmodule
