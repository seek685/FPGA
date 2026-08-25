module regfile (
    // Clock and write enable
    input  logic        clk,
    input  logic        we,
    // Write address and data
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    // Read addresses and data
    input  logic [4:0]  raddr1,
    input  logic [4:0]  raddr2,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    // 32-bit register file with 32 registers.
    logic [31:0] regs [0:31];

    // x0 is hardwired to zero by RV32I, so writes to address 0 are blocked.
    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0)) regs[waddr] <= wdata;
    end

    // Return the corresponding data based on the read address; x0 always returns zero.
    always_comb begin
        rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];
        rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];
    end
endmodule
