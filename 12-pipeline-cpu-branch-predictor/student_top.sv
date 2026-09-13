`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2025 06:21:13 PM
// Design Name: 
// Module Name: student_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module student_top#(
    parameter                           P_SW_CNT            = 64,
    parameter                           P_LED_CNT           = 32,
    parameter                           P_SEG_CNT           = 40,
    parameter                           P_KEY_CNT           = 8
) (
    input                                       w_cpu_clk     ,
    input                                       w_clk_50Mhz   ,
    input                                       w_clk_rst     ,
    input  [P_KEY_CNT - 1:0]                    virtual_key   ,
    input  [P_SW_CNT  - 1:0]                    virtual_sw    ,

    output [P_LED_CNT - 1:0]                    virtual_led   ,
    output [P_SEG_CNT - 1:0]                    virtual_seg   
);

    // IROM request/response
    logic irom_req_valid;
    logic irom_req_ready;
    logic [31:0] irom_req_pc;
    logic [11:0] irom_req_ghr_snapshot;
    logic [31:0] irom_req_pred_target;
    logic [11:0] irom_req_pht_index;
    logic irom_req_pred_taken;

    logic irom_resp_valid;
    logic irom_resp_ready;
    logic [31:0] irom_resp_pc;
    logic [31:0] irom_resp_instr;
    logic [11:0] irom_resp_ghr_snapshot;
    logic [31:0] irom_resp_pred_target;
    logic [11:0] irom_resp_pht_index;
    logic irom_resp_pred_taken;
    logic irom_flush;

    logic [11:0] inst_addr;
    logic [31:0] instruction;

    // perip
    logic [31:0] perip_addr;
    logic [31:0] perip_wdata;
    logic perip_wen;
    logic [1:0] perip_mask;
    logic [31:0] perip_rdata;
    myCPU Core_cpu (
        .cpu_rst(w_clk_rst),
        .cpu_clk(w_cpu_clk),

        // Interface to IROM driver
        .irom_req_valid(irom_req_valid),
        .irom_req_ready(irom_req_ready),
        .irom_req_pc(irom_req_pc),
        .irom_req_ghr_snapshot(irom_req_ghr_snapshot),
        .irom_req_pred_target(irom_req_pred_target),
        .irom_req_pht_index(irom_req_pht_index),
        .irom_req_pred_taken(irom_req_pred_taken),
        .irom_resp_valid(irom_resp_valid),
        .irom_resp_ready(irom_resp_ready),
        .irom_resp_pc(irom_resp_pc),
        .irom_resp_instr(irom_resp_instr),
        .irom_resp_ghr_snapshot(irom_resp_ghr_snapshot),
        .irom_resp_pred_target(irom_resp_pred_target),
        .irom_resp_pht_index(irom_resp_pht_index),
        .irom_resp_pred_taken(irom_resp_pred_taken),
        .irom_flush(irom_flush),

        // Interface to DRAM & periphera
        .perip_addr(perip_addr),     
        .perip_wen(perip_wen),     
        .perip_mask(perip_mask),   
        .perip_wdata(perip_wdata),    
        .perip_rdata(perip_rdata)     
    );

    irom_driver u_irom_driver (
        .clk (w_cpu_clk),
        .rst_n(!w_clk_rst),
        .flush(irom_flush),
        .req_valid(irom_req_valid),
        .req_ready(irom_req_ready),
        .req_pc(irom_req_pc),
        .req_ghr_snapshot(irom_req_ghr_snapshot),
        .req_pred_target (irom_req_pred_target),
        .req_pht_index(irom_req_pht_index),
        .req_pred_taken(irom_req_pred_taken),
        .resp_valid(irom_resp_valid),
        .resp_ready(irom_resp_ready),
        .resp_pc(irom_resp_pc),
        .resp_instr(irom_resp_instr),
        .resp_ghr_snapshot(irom_resp_ghr_snapshot),
        .resp_pred_target (irom_resp_pred_target),
        .resp_pht_index(irom_resp_pht_index),
        .resp_pred_taken(irom_resp_pred_taken),
        .bram_addr(inst_addr),
        .bram_data(instruction)
    );

    IROM Mem_IROM (
        .clka(w_cpu_clk),
        .addra(inst_addr),
        .douta(instruction)
    );
    
    perip_bridge bridge_inst (
        .clk				(w_cpu_clk),
        .cnt_clk            (w_clk_50Mhz),
        .rst                (w_clk_rst),
        .perip_addr			(perip_addr),
        .perip_wdata		(perip_wdata),
        .perip_wen			(perip_wen),
        .perip_mask			(perip_mask),
        .perip_rdata		(perip_rdata),
        .virtual_sw_input	(virtual_sw),
        .virtual_key_input	(virtual_key),	
        .virtual_seg_output	(virtual_seg),
        .virtual_led_output (virtual_led)
    );

endmodule
