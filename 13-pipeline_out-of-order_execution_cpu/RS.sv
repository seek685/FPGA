module RS(
    input logic clk,
    input logic rst_n,
    input logic flush,

    output logic rs_alloc_ready,
    input logic dispatch_fire,
    input logic [2:0] dispatch_rob_tag,
    input logic [3:0] dispatch_alu_control,

    input logic [31:0] dispatch_rs1_value,
    input logic dispatch_rs1_ready,
    input logic [2:0] dispatch_rs1_tag,
    input logic [31:0] dispatch_rs2_value,
    input logic dispatch_rs2_ready,
    input logic [2:0] dispatch_rs2_tag,

    input logic wb_valid,
    input logic [2:0] wb_tag,
    input logic [31:0] wb_value,

    input logic [2:0] rob_head_tag,
    output logic issue_valid,
    output logic [2:0]issue_rob_tag,
    output logic [3:0] issue_alu_control,
    output logic [31:0] issue_rs1_value,
    output logic [31:0] issue_rs2_value,

    input logic [2:0] dispatch_kind,
    input logic [31:0] dispatch_pc,
    input logic [31:0] dispatch_imm,
    input logic [2:0] dispatch_funct3,
    input logic [1:0] dispatch_alu_src_a,
    input logic dispatch_alu_src_b,
    output logic [2:0] issue_kind,
    output logic [31:0] issue_pc,
    output logic [31:0] issue_imm,
    output logic [2:0] issue_funct3,
    output logic [1:0] issue_alu_src_a,
    output logic issue_alu_src_b

);  
    logic [1:0] rs_spare_index;
    logic issue_ready;
    logic [2:0]age;
    logic [1:0]index;
    typedef struct packed{
        logic [31:0] rs1;
        logic [31:0] rs2;
        logic [2:0]dest_tag;
        logic [3:0] op;//not opcode
        logic busy;
        logic rs1_ready;
        logic rs2_ready;
        logic [2:0]tag_1;
        logic [2:0]tag_2;
        
        logic [2:0] kind;
        logic [31:0] pc;
        logic [31:0] imm;
        logic [2:0] funct3;
        logic [1:0] alu_src_a;
        logic alu_src_b;
    }RS_t;
    RS_t RS[3:0];

    always_comb begin
        issue_ready=0;
        index=0;
        age=0;
        for(int i=0;i<4;i++)begin
            if(RS[i].busy&&RS[i].rs1_ready&&RS[i].rs2_ready)begin
                if(issue_ready==0)begin
                    issue_ready=1;
                    age=RS[i].dest_tag-rob_head_tag;
                    index=i;
                end
                else begin
                    if((RS[i].dest_tag-rob_head_tag)<age)begin
                        age=RS[i].dest_tag-rob_head_tag;
                        index=i;
                    end
                end
            end
        end
        if(issue_ready)begin
            issue_valid=1;
            issue_rob_tag=RS[index].dest_tag;
            issue_alu_control=RS[index].op;
            issue_rs1_value=RS[index].rs1;
            issue_rs2_value=RS[index].rs2;
            
            issue_kind=RS[index].kind;
            issue_pc=RS[index].pc;
            issue_imm=RS[index].imm;
            issue_funct3=RS[index].funct3;
            issue_alu_src_a=RS[index].alu_src_a;
            issue_alu_src_b=RS[index].alu_src_b;
            
        end
        else begin
            issue_valid=0;
            issue_rob_tag=3'd0;
            issue_alu_control=4'd0;
            issue_rs1_value=32'd0;
            issue_rs2_value=32'd0;

            issue_kind=3'd0;
            issue_pc=32'd0;
            issue_imm=32'd0;
            issue_funct3=3'd0;
            issue_alu_src_a=2'd0;
            issue_alu_src_b=0;
        end

        if(RS[0].busy==0)begin
            rs_spare_index=0;
            rs_alloc_ready=1;
        end
        else if(RS[1].busy==0)begin
            rs_spare_index=1;
            rs_alloc_ready=1;
        end
        else if(RS[2].busy==0)begin
            rs_spare_index=2;
            rs_alloc_ready=1;
        end
        else if(RS[3].busy==0)begin
            rs_spare_index=3;
            rs_alloc_ready=1;
        end
        else if(issue_ready)begin
            rs_spare_index=index;
            rs_alloc_ready=1;
        end
        else begin
            rs_alloc_ready=0;
            rs_spare_index=0;
        end


        
        //case(~rs_busy&(rs_busy+1))
        //    4'b0001:rs_spare_index=2'd0;
        //    4'b0010:rs_spare_index=2'd1;
        //    4'b0100:rs_spare_index=2'd2;
        //    4'b1000:rs_spare_index=2'd3;
        //    default:rs_spare_inedx=2'd0;
        //endcase
        //if(rs_busy!=4'b1111)rs_alloc_ready=1;
        //else if(rs_busy==4'b1111&&issue_ready)rs_alloc_ready=1;
        //else rs_alloc_ready=0;
        //RS[2'd0].rs1=32'd0;
        //RS[2'd0].rs2=32'd0;
        //RS[2'd1].rs1=32'd0;
        //RS[2'd1].rs2=32'd0;
        //RS[2'd2].rs1=32'd0;
        //RS[2'd2].rs2=32'd0;
        //RS[2'd3].rs1=32'd0;
        //RS[2'd3].rs2=32'd0;
//
        //if(wb_valid)begin
        //    if(wb_tag==RS[2'd0].tag_1)RS[2'd0].rs1=wb_value;
        //    if(wb_tag==RS[2'd0].tag_2)RS[2'd0].rs2=wb_value;
        //    if(wb_tag==RS[2'd1].tag_1)RS[2'd1].rs1=wb_value;
        //    if(wb_tag==RS[2'd1].tag_2)RS[2'd1].rs2=wb_value;
        //    if(wb_tag==RS[2'd2].tag_1)RS[2'd2].rs1=wb_value;
        //    if(wb_tag==RS[2'd2].tag_2)RS[2'd2].rs2=wb_value;
        //    if(wb_tag==RS[2'd3].tag_1)RS[2'd3].rs1=wb_value;
        //    if(wb_tag==RS[2'd3].tag_2)RS[2'd3].rs2=wb_value;
        //end
        
        //for(int i=0;i<4;i++)begin
        //    if(RS[i].busy&&RS[i].rs1_ready&&RS[i].rs2_ready)
        //        age[i]=RS[i].dest_tag-rob_head_tag;
        //    else age[i]=3'd7;
        //end
        //older=2'd0;
        //for(int i=0;i<4;i++)begin
        //    if(age[0]>age[i])begin
        //        age[0]=age[i];
        //        older=i;
        //    end
        //end
        
    

    end

    always_ff @(posedge clk)begin
        if(!rst_n)begin
            for(int i=0;i<4;i++)begin
                RS[i].busy<=1'b0;
            end
        end
        else if(flush)begin
            for(int i=0;i<4;i++)begin
                RS[i].busy<=1'b0;
            end
        end
        else begin
            if(dispatch_fire==1)begin //allocate RS
                //RS[~rs_busy&(rs_busy+1)].busy<=1;
                //RS[~rs_busy&(rs_busy+1)].rs1<=dispatch_rs1_value;
                //RS[~rs_busy&(rs_busy+1)].rs2<=dispatch_rs2_value;
                //RS[~rs_busy&(rs_busy+1)].rs1_ready<=dispatch_rs1_ready;
                //RS[~rs_busy&(rs_busy+1)].rs2_ready<=dispatch_rs2_ready;
                //RS[~rs_busy&(rs_busy+1)].tag_1<=dispatch_rs1_tag;
                //RS[~rs_busy&(rs_busy+1)].tag_2<=dispatch_rs2_tag;
                //RS[~rs_busy&(rs_busy+1)].dest_tag<=dispatch_rob_tag;
                //RS[~rs_busy&(rs_busy+1)].op<=dispatch_alu_control;

                //map(reflect) vectors to spare_index 
                RS[rs_spare_index].busy<=1;
                RS[rs_spare_index].rs1<=dispatch_rs1_value;
                RS[rs_spare_index].rs2<=dispatch_rs2_value;
                RS[rs_spare_index].rs1_ready<=dispatch_rs1_ready;
                RS[rs_spare_index].rs2_ready<=dispatch_rs2_ready;
                RS[rs_spare_index].tag_1<=dispatch_rs1_tag;
                RS[rs_spare_index].tag_2<=dispatch_rs2_tag;
                RS[rs_spare_index].dest_tag<=dispatch_rob_tag;
                RS[rs_spare_index].op<=dispatch_alu_control;
                RS[rs_spare_index].kind<=dispatch_kind;
                RS[rs_spare_index].pc<=dispatch_pc;
                RS[rs_spare_index].imm<=dispatch_imm;
                RS[rs_spare_index].funct3<=dispatch_funct3;
                RS[rs_spare_index].alu_src_a<=dispatch_alu_src_a;
                RS[rs_spare_index].alu_src_b<=dispatch_alu_src_b;
                //rs_busy<=(rs_busy+1)|rs_busy;
                
            end
            if(wb_valid)begin //broadcast
                if(RS[2'd0].busy&&wb_tag==RS[2'd0].tag_1&&RS[2'd0].rs1_ready!=1)begin
                    RS[2'd0].rs1_ready<=1;
                    RS[2'd0].rs1<=wb_value;
                end
                if(RS[2'd0].busy&&wb_tag==RS[2'd0].tag_2&&RS[2'd0].rs2_ready!=1)begin 
                    RS[2'd0].rs2_ready<=1;
                    RS[2'd0].rs2<=wb_value;
                end
                if(RS[2'd1].busy&&wb_tag==RS[2'd1].tag_1&&RS[2'd1].rs1_ready!=1)begin 
                    RS[2'd1].rs1_ready<=1;
                    RS[2'd1].rs1<=wb_value;
                end
                if(RS[2'd1].busy&&wb_tag==RS[2'd1].tag_2&&RS[2'd1].rs2_ready!=1)begin 
                    RS[2'd1].rs2_ready<=1;
                    RS[2'd1].rs2<=wb_value;
                end
                if(RS[2'd2].busy&&wb_tag==RS[2'd2].tag_1&&RS[2'd2].rs1_ready!=1)begin 
                    RS[2'd2].rs1_ready<=1;
                    RS[2'd2].rs1<=wb_value;
                end
                if(RS[2'd2].busy&&wb_tag==RS[2'd2].tag_2&&RS[2'd2].rs2_ready!=1)begin 
                    RS[2'd2].rs2_ready<=1;
                    RS[2'd2].rs2<=wb_value;
                end
                if(RS[2'd3].busy&&wb_tag==RS[2'd3].tag_1&&RS[2'd3].rs1_ready!=1)begin 
                    RS[2'd3].rs1_ready<=1;
                    RS[2'd3].rs1<=wb_value;
                end
                if(RS[2'd3].busy&&wb_tag==RS[2'd3].tag_2&&RS[2'd3].rs2_ready!=1)begin 
                    RS[2'd3].rs2_ready<=1;
                    RS[2'd3].rs2<=wb_value;
                end
            end
            if(issue_ready&&!dispatch_fire)begin
                RS[index].busy<=0;
            end
            else if(issue_ready&&dispatch_fire&&index==rs_spare_index)begin
                RS[index].busy<=1;
            end
            else if(issue_ready&&dispatch_fire&&index!=rs_spare_index)begin
                RS[index].busy<=0;
            end
        end
    end


endmodule
