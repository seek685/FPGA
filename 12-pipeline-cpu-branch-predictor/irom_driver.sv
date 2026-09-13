module irom_driver #(
    parameter logic [31:0] ROM_BASE_ADDR = 32'h8000_0000,
    parameter integer      ROM_ADDR_WIDTH = 12,
    parameter integer      ROM_DEPTH_WORDS = 4096,
    parameter integer      GHR_WIDTH = 12,
    parameter integer      PHT_INDEX_WIDTH = 12
) (
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       flush,

    input  logic                       req_valid,
    output logic                       req_ready,
    input  logic [31:0]                req_pc,
    input  logic [GHR_WIDTH-1:0]       req_ghr_snapshot,
    input  logic [31:0]                req_pred_target,
    input  logic [PHT_INDEX_WIDTH-1:0] req_pht_index,
    input  logic                       req_pred_taken,

    output logic                       resp_valid,
    input  logic                       resp_ready,
    output logic [31:0]                resp_pc,
    output logic [31:0]                resp_instr,
    output logic [GHR_WIDTH-1:0]       resp_ghr_snapshot,
    output logic [31:0]                resp_pred_target,
    output logic [PHT_INDEX_WIDTH-1:0] resp_pht_index,
    output logic                       resp_pred_taken,

    output logic [ROM_ADDR_WIDTH-1:0]  bram_addr,
    input  logic [31:0]                bram_data
);

    localparam logic [31:0] ROM_LIMIT_ADDR =
        ROM_BASE_ADDR + (ROM_DEPTH_WORDS * 4);

    logic                       pending_valid;
    logic [31:0]                pending_pc;
    logic [GHR_WIDTH-1:0]       pending_ghr_snapshot;
    logic [31:0]                pending_pred_target;
    logic [PHT_INDEX_WIDTH-1:0] pending_pht_index;
    logic                       pending_pred_taken;
    logic                       pending_pc_valid;

    logic response_slot_available;
    logic req_fire;
    logic [31:0] bram_pc;

    assign response_slot_available = !resp_valid || resp_ready;
    assign req_ready = !pending_valid || response_slot_available;
    assign req_fire = req_valid && req_ready;

    // During backpressure, keep the pending address on the always-enabled BRAM.
    assign bram_pc = req_fire ? req_pc :
                     pending_valid ? pending_pc : req_pc;
    assign bram_addr = (bram_pc - ROM_BASE_ADDR) >> 2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_valid       <= 1'b0;
            pending_pc          <= 32'd0;
            pending_ghr_snapshot <= '0;
            pending_pred_target <= 32'd0;
            pending_pht_index   <= '0;
            pending_pred_taken  <= 1'b0;
            pending_pc_valid    <= 1'b0;

            resp_valid          <= 1'b0;
            resp_pc             <= 32'd0;
            resp_instr          <= 32'd0;
            resp_ghr_snapshot   <= '0;
            resp_pred_target    <= 32'd0;
            resp_pht_index      <= '0;
            resp_pred_taken     <= 1'b0;
        end
        else if (flush) begin
            pending_valid <= 1'b0;
            resp_valid    <= 1'b0;
        end
        else begin
            if (response_slot_available) begin
                resp_valid <= pending_valid;
                if (pending_valid) begin
                    resp_pc           <= pending_pc;
                    resp_instr        <= pending_pc_valid ? bram_data : 32'h0000_0013;
                    resp_ghr_snapshot <= pending_ghr_snapshot;
                    resp_pred_target  <= pending_pred_target;
                    resp_pht_index    <= pending_pht_index;
                    resp_pred_taken   <= pending_pred_taken;
                end
            end

            if (pending_valid && response_slot_available)
                pending_valid <= 1'b0;

            if (req_fire) begin
                pending_valid        <= 1'b1;
                pending_pc           <= req_pc;
                pending_ghr_snapshot <= req_ghr_snapshot;
                pending_pred_target  <= req_pred_target;
                pending_pht_index    <= req_pht_index;
                pending_pred_taken   <= req_pred_taken;
                pending_pc_valid     <= (req_pc[1:0] == 2'b00) &&
                                        (req_pc >= ROM_BASE_ADDR) &&
                                        (req_pc < ROM_LIMIT_ADDR);
            end
        end
    end

endmodule
