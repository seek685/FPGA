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

    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0)) regs[waddr] <= wdata;
    end

    always_comb begin
        // Write-through makes a WB write visible to an ID read in the same cycle.
        rdata1 = (raddr1 == 5'd0) ? 32'd0 :
                 (we && (waddr != 5'd0) && (waddr == raddr1)) ? wdata : regs[raddr1];
        rdata2 = (raddr2 == 5'd0) ? 32'd0 :
                 (we && (waddr != 5'd0) && (waddr == raddr2)) ? wdata : regs[raddr2];
    end
endmodule
