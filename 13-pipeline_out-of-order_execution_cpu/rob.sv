module rob(
    input logic clk,
    input logic rst_n,
    input logic flush,
    //rename
    output logic alloc_ready,
    output logic [2:0] alloc_tag,
    input logic alloc_fire,
    input logic [4:0] alloc_rd,
    input logic alloc_reg_write,
    input logic [31:0] alloc_pc,

    input logic [2:0] alloc_kind,
    //add funct3
    input logic [2:0] alloc_funct3,
    input logic alloc_pred_taken,
    input logic [31:0] alloc_pred_target,
    input logic [11:0] alloc_pht_index,
    input logic [11:0] alloc_ghr_snapshot,

    //inquire/query 
    //RS inquire RAT ,RAT inquire ROB
    input  logic [2:0] rs1_tag,
    output logic  rs1_valid,
    output logic  rs1_ready,
    output logic  [31:0]rs1_value,
    input  logic [2:0] rs2_tag,
    output logic  rs2_valid,
    output logic  rs2_ready,
    output logic  [31:0]rs2_value,
    //write back(wirte ROB)
    input logic wb_actual_taken,
    input logic [31:0] wb_actual_target,
    input logic [31:0] wb_actual_next_pc,

    input logic [2:0] wb_tag,
    input logic wb_valid,
    input logic [31:0] wb_value,
    //commit
    output logic commit_valid,//head valid and can commit
    output logic [2:0] commit_tag,
    output logic [4:0] commit_rd,
    output logic commit_reg_write,
    output logic [31:0] commit_value,
    output logic [31:0] commit_pc,

    input logic commit_ready,//wether commit can be received or not
    output logic commit_fire,//actually commit
    output logic [2:0]commit_kind,
    output logic commit_actual_taken,
    output logic [31:0] commit_actual_target,
    output logic [31:0] commit_actual_next_pc,
    output logic commit_pred_taken,
    output logic [31:0] commit_pred_target,
    output logic [11:0] commit_pht_index,
    output logic [11:0] commit_ghr_snapshot,

    output logic [2:0] head_sent_RS,
    //add access memory (in)
    input logic mem_prepare_valid,
    input logic [2:0] mem_prepare_tag,
    input logic [31:0] mem_prepare_addr,
    input logic [31:0] mem_prepare_store_data,
    //out
    output logic head_valid,
    output logic [2:0] head_kind,
    output logic head_mem_prepare,
    output logic [31:0] head_mem_addr,
    output logic [31:0] head_store_data,
    output logic [2:0] head_funct3

);
    logic [2:0] head;
    logic [2:0] tail;
    logic [3:0] count;
    typedef struct packed{
        logic valid;
        logic ready;
        logic [4:0] rd;
        logic reg_write;
        logic [31:0] value;
        logic [31:0] pc;
        //judge alu_src's input and support j'type instruction
        logic [2:0] kind;
        logic actual_taken;
        logic [31:0] actual_target;
        logic [31:0] actual_next_pc;
        //suport load and store
        logic mem_prepare;//address and data is all ready
        logic [31:0] mem_addr;
        logic [31:0] store_data;
        logic [2:0] funct3;//judge LB/LH/LW/LBU/LHU or SB/SH/SW
        logic pred_taken;
        logic [31:0] pred_target;
        logic [11:0] pht_index;
        logic [11:0] ghr_snapshot;
    }ROB_t;
    ROB_t ROB [0:7];


    always_comb begin
        //if(wb_valid)begin
        //    ROB[wb_tag].value=wb_value;
        //    ROB[wb_tag].ready=1'b1;
        //end

        

        head_sent_RS=head;

        commit_tag=head;
        commit_rd=5'd0;
        commit_reg_write=0;
        commit_value=32'd0;
        commit_pc=32'd0;
        commit_kind=3'd0;
        commit_actual_target=32'd0;
        commit_actual_next_pc=32'd0;
        commit_actual_taken=0;
        commit_pred_taken=1'b0;
        commit_pred_target=32'd0;
        commit_pht_index=12'd0;
        commit_ghr_snapshot=12'd0;
        if(ROB[head].ready==1 && ROB[head].valid==1 &&count!=0)begin
            commit_valid=1;
            commit_tag=head;
            commit_rd=ROB[head].rd;
            commit_reg_write=ROB[head].reg_write;
            commit_value=ROB[head].value;
            commit_pc=ROB[head].pc;
            commit_kind=ROB[head].kind;
            commit_actual_target=ROB[head].actual_target;
            commit_actual_taken=ROB[head].actual_taken;
            commit_actual_next_pc=ROB[head].actual_next_pc;
            commit_pred_taken=ROB[head].pred_taken;
            commit_pred_target=ROB[head].pred_target;
            commit_pht_index=ROB[head].pht_index;
            commit_ghr_snapshot=ROB[head].ghr_snapshot;
        end else commit_valid=0;

        //support load instruction 
        head_valid=0;
        head_kind=3'd0;
        head_mem_prepare=0;
        head_mem_addr=32'd0;
        head_store_data=32'd0;
        head_funct3=3'd0;
        if(ROB[head].valid==1&&count!=0)begin
            head_valid=1;
            head_kind=ROB[head].kind;
            head_mem_prepare=ROB[head].mem_prepare;
            head_mem_addr=ROB[head].mem_addr;
            head_store_data=ROB[head].store_data;
            head_funct3=ROB[head].funct3;
        end
        


        if(commit_valid&&commit_ready)commit_fire=1;
        else commit_fire=0;

        alloc_ready=0;
        alloc_tag=3'd0;
        if(count<4'd8)begin
            alloc_ready=1;
            alloc_tag=tail;
        end
        else if(count==4'd8&&commit_fire==1)begin
            alloc_ready=1;
            alloc_tag=tail;
        end

        if(ROB[rs1_tag].ready==1&&ROB[rs1_tag].valid==1)begin
            rs1_valid=1;
            rs1_ready=1;
            rs1_value=ROB[rs1_tag].value;
        end
        else if(ROB[rs1_tag].ready==0&&ROB[rs1_tag].valid==1)begin
            rs1_valid=1;
            rs1_ready=0;
            rs1_value=32'd0;
        end
        else begin 
            rs1_valid=0;
            rs1_ready=0;
            rs1_value=32'd0;
        end

        if(ROB[rs2_tag].ready==1&&ROB[rs2_tag].valid==1)begin
            rs2_valid=1;
            rs2_ready=1;
            rs2_value=ROB[rs2_tag].value;
        end
        else if(ROB[rs2_tag].ready==0&&ROB[rs2_tag].valid==1)begin
            rs2_valid=1;
            rs2_ready=0;
            rs2_value=32'd0;
        end
        else begin 
            rs2_valid=0;
            rs2_ready=0;
            rs2_value=32'd0;
        end

        
    end

    always_ff@(posedge clk)begin
        if(!rst_n)begin
            head<=0;
            tail<=0;
            count<=0;
            for(int i=0;i<8;i++)begin
                ROB[i].ready<=0;
                ROB[i].valid<=0;
            end
        end
        else if(flush)begin
            head<=3'd0;
            tail<=3'd0;
            count<=4'd0;
            for(int i=0;i<8;i++)begin
                ROB[i].ready<=1'b0;
                ROB[i].valid<=1'b0;
                ROB[i].mem_prepare<=1'b0;
            end
        end
        else begin
            //commit
            if(commit_fire==1)begin
                //realse ROB[head]
                ROB[head].ready<=1'b0;
                ROB[head].valid<=1'b0;
                
                //commit_valid<=1;
                //commit_tag<=head;
                //commit_rd<=ROB[head].rd;
                //commit_reg_write<=ROB[head].reg_write;
                //commit_value<=ROB[head].value;
                //commit_pc<=ROB[head].pc;
                head<=head+3'd1;
                //count<=count-4'd1;
            end
            //allocate
            if(alloc_fire==1)begin
                //count<=count+4'd1;
                ROB[tail].valid<=1'b1;
                ROB[tail].ready<=1'b0;
                ROB[tail].rd<=alloc_rd;
                ROB[tail].reg_write<=alloc_reg_write;
                ROB[tail].pc<=alloc_pc;
                ROB[tail].kind<=alloc_kind;
                ROB[tail].mem_prepare<=0;
                ROB[tail].mem_addr<=32'd0;
                ROB[tail].store_data<=32'd0;
                ROB[tail].funct3<=alloc_funct3;
                ROB[tail].pred_taken<=alloc_pred_taken;
                ROB[tail].pred_target<=alloc_pred_target;
                ROB[tail].pht_index<=alloc_pht_index;
                ROB[tail].ghr_snapshot<=alloc_ghr_snapshot;
                //alloc_tag<=tail;
                tail<=tail+3'd1;
                //alloc_ready<=1'b1;
            end
            if(wb_valid)begin
                ROB[wb_tag].value<=wb_value;
                ROB[wb_tag].actual_taken<=wb_actual_taken;
                ROB[wb_tag].actual_target<=wb_actual_target;
                ROB[wb_tag].actual_next_pc<=wb_actual_next_pc;
                ROB[wb_tag].ready<=1'b1;
            end

            if(mem_prepare_valid)begin
                ROB[mem_prepare_tag].mem_prepare<=1'b1;
                ROB[mem_prepare_tag].mem_addr<=mem_prepare_addr;
                ROB[mem_prepare_tag].store_data<=mem_prepare_store_data;
                if(ROB[mem_prepare_tag].kind==3'd5)
                    ROB[mem_prepare_tag].ready<=1'b1;
            end

            if(alloc_fire==0&&commit_fire)begin
                count<=count-4'd1;
            end
            else if(commit_fire==0&&alloc_fire==1)begin
                count<=count+4'd1;
            end
        end
    end
endmodule
