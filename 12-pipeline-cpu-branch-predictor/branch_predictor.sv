module branch_predictor #(
    parameter PC_WIDTH        = 32,
    parameter GHR_WIDTH       = 12,
    parameter PHT_INDEX_WIDTH = 12,
    parameter PHT_ENTRIES     = 4096,
    parameter BTB_INDEX_WIDTH = 9,
    parameter BTB_ENTRIES     = 512,
    parameter BTB_TAG_WIDTH   = 21
)(
    input  logic                       clk,
    input  logic                       rst_n,
    // IF
    input  logic [PC_WIDTH-1:0]        if_pc,
    input  logic                       if_is_branch,//myCPU decode and deliver while IF
    input  logic                       if_accept,

    output logic                       if_pred_taken,
    output logic [PC_WIDTH-1:0]        if_pred_target,
    output logic [PHT_INDEX_WIDTH-1:0] if_pht_index,
    output logic [GHR_WIDTH-1:0]       if_ghr_snapshot,
    // EX wirte back pht btb
    input  logic                       ex_train_valid,
    input  logic [PC_WIDTH-1:0]        ex_branch_pc,
    input  logic [PHT_INDEX_WIDTH-1:0] ex_pht_index,
    input  logic                       ex_actual_taken,
    input  logic [PC_WIDTH-1:0]        ex_actual_target,
    // EX write back GHR
    input  logic                       ex_ghr_recover_valid,
    input  logic [GHR_WIDTH-1:0]       ex_ghr_recover_value
);
    logic [GHR_WIDTH-1:0] ghr_q;
    logic [1:0] pht_q [0:PHT_ENTRIES-1];
    logic                     btb_valid_q  [0:BTB_ENTRIES-1];
    logic [BTB_TAG_WIDTH-1:0] btb_tag_q    [0:BTB_ENTRIES-1];
    logic [PC_WIDTH-1:0]      btb_target_q [0:BTB_ENTRIES-1];

    logic [PHT_INDEX_WIDTH-1:0] if_pc_history;
    logic [PHT_INDEX_WIDTH-1:0] if_pht_index_comb;
    logic [BTB_INDEX_WIDTH-1:0] if_btb_index;
    logic [BTB_TAG_WIDTH-1:0]   if_btb_tag;
    logic [1:0]                 if_pht_counter;
    logic                       if_pht_taken;
    logic                       if_btb_hit;
    logic [PC_WIDTH-1:0]        if_btb_target;
    logic                       if_spec_update_valid;

    logic [8:0] ex_btb_index;
    assign ex_btb_index=ex_branch_pc[10:2];

    assign if_pc_history=if_pc[13:2];
    assign if_pht_index_comb=if_pc_history^ghr_q;//pht'index
    assign if_btb_index=if_pc[13:2];//btb'index 
    assign if_btb_tag=if_pc[31:11];//btb'check

    //pht  btb
    assign if_pht_counter=pht_q[if_pht_index_comb];//pht'00 01 10 11
    assign if_pht_taken=if_pht_counter[1];// jump or not
    assign if_btb_hit=(btb_valid_q[if_btb_index]==1&&btb_tag_q[if_btb_index]==if_btb_tag);
    assign if_btb_target=btb_target_q[if_btb_index];
    assign if_spec_update_valid=if_accept&&if_is_branch;

    always_comb begin
        if(if_btb_hit&&if_spec_update_valid)begin
            if_pred_taken=if_pht_taken&&if_is_branch&&if_btb_hit;
            if_pred_target=if_btb_target;
            if_pht_index=if_pht_index_comb;
            if_ghr_snapshot=ghr_q;
        end
        else begin
            if_pred_taken=1'b0;
            if_pred_target=if_pc+32'd4;
            if_pht_index=if_pht_index_comb;
            if_ghr_snapshot=ghr_q;
        end
    end
    always_ff@(posedge clk) begin
        if(!rst_n)begin
            ghr_q=12'd0;
            for(int i=0;i<PHT_ENTRIES;i++)begin
                pht_q[i]<=2'b01;
            end
        end
        if(ex_train_valid)begin
            btb_valid_q[ex_btb_index]<=1'b1;
            btb_tag_q[ex_btb_index]<=ex_branch_pc[31:11];
            btb_target_q[ex_btb_index]<=ex_actual_target;
            pht_q[ex_pht_index]<=ex_actual_taken+2'd1;
            ghr_q<=(ex_ghr_recover_valid)?{ex_ghr_recover_value[11:0],ex_actual_taken};
        end
    end


endmodule