module rename(
    input logic clk,
    input logic rst_n,

//decode    
    input logic dec_valid,//current instruction is valid
    output logic dec_ready,//RS and rob have spare
    input logic [31:0] dec_pc,
    input logic [31:0] dec_imm,
    input logic [4:0] dec_rs1,
    input logic [4:0] dec_rs2,
    input logic [4:0] dec_rd,
    input logic dec_reg_write,
    input logic [3:0] dec_alu_control,
    //if rs1(alu_a) read rs1/pc   rs2 read rs2/imm
    input logic dec_use_rs1,
    input logic dec_use_rs2,
    input logic dec_rs1_is_pc,
    input logic dec_rs2_is_imm,

//ARF
    output logic [4:0] arf_rs1_addr,
    input logic [31:0] arf_rs1_value,
    output logic [4:0] arf_rs2_addr,
    input logic [31:0] arf_rs2_value,
//rob
    input logic rob_alloc_ready,
    input logic [2:0] rob_alloc_tag,
    output logic rob_alloc_fire,
    output logic [4:0] rob_rd,//if RAT no reflect read ARF and alloc RAT[rd]
    output logic rob_alloc_reg_write,
    output logic [31:0]rob_alloc_pc,

    output logic [2:0]rob_rs1_tag,//if RAT reflect read
    input logic rob_rs1_valid,
    input logic rob_rs1_ready,
    input logic [31:0]rob_rs1_value,
    output logic [2:0]rob_rs2_tag,
    input logic rob_rs2_valid,
    input logic rob_rs2_ready,
    input logic [31:0]rob_rs2_value,
//RS
    input logic rs_alloc_ready,
    output logic dispatch_fire,
    output logic [2:0] dispatch_rob_tag,
    output logic [3:0] dispatch_alu_control,
    output logic [31:0] dispatch_rs1_value,
    output logic dispatch_rs1_ready,
    output logic [2:0] dispatch_rs1_tag,
    output logic [31:0] dispatch_rs2_value,
    output logic dispatch_rs2_ready,
    output logic [2:0] dispatch_rs2_tag,

    input logic wb_valid,
    input logic [2:0]wb_tag,
    input logic [31:0]wb_value,
//commit
    input logic commit_valid,
    input logic [2:0] commit_tag,
    input logic [4:0] commit_rd,
    input logic commit_reg_write

);
typedef struct packed{
    logic valid;
    logic [2:0] tag;
}RAT_t;
RAT_t RAT [31:0];
//assign RAT[0].valid=0;

always_comb begin
    //rob and rs can be allocated
    if(rob_alloc_ready&&rs_alloc_ready&&dec_valid)begin
        dec_ready=1;
        dispatch_fire=1;
        rob_alloc_fire=1;
    end
    else if(rob_alloc_ready&&rs_alloc_ready&&dec_valid==0)begin
        dec_ready=1;
        dispatch_fire=0;
        rob_alloc_fire=0;
    end
    else begin
        dec_ready=0;
        dispatch_fire=0;
        rob_alloc_fire=0;
    end
    if(dec_ready&&dec_valid)begin
        rob_rs1_tag=RAT[dec_rs1].tag;
        rob_rs2_tag=RAT[dec_rs2].tag;
        dispatch_alu_control=dec_alu_control;
        //dispatch_rob_tag=RAT[dec_rd].tag;
        dispatch_rob_tag=rob_alloc_tag;
        rob_rd=dec_rd;
        rob_alloc_reg_write=dec_reg_write;

        arf_rs1_addr=dec_rs1;
        dispatch_rs1_tag=RAT[dec_rs1].tag;
        rob_alloc_pc=dec_pc;

        dispatch_rs1_value=32'd0;
        dispatch_rs1_ready=0;
        if(!dec_use_rs1&&dec_rs1_is_pc)begin   //pc
            dispatch_rs1_value=dec_pc;
            dispatch_rs1_ready=1;
        end
        else if(dec_use_rs1&&dec_rs1_is_pc==0)begin  //rs1
            if(dec_rs1==0)begin//rs1 is x0
                dispatch_rs1_value=32'd0;
                dispatch_rs1_ready=1;
            end
            else if(RAT[dec_rs1].valid==0)begin
                //arf_rs1_addr=dec_rs1;
                dispatch_rs1_value=arf_rs1_value;
                dispatch_rs1_ready=1;
            end
            else if(RAT[dec_rs1].valid&&wb_valid&&wb_tag==RAT[dec_rs1].tag)begin
                dispatch_rs1_value=wb_value;
                dispatch_rs1_ready=1;
                //dispatch_rs1_tag=RAT[dec_rs1].tag;
            end
            else if(RAT[dec_rs1].valid&&rob_rs1_ready&&rob_rs1_valid)begin
                dispatch_rs1_value=rob_rs1_value;
                dispatch_rs1_ready=1;
                //dispatch_rs1_tag=RAT[dec_rs1].tag;
            end
            else begin //RAT reflect but rob not ready
                dispatch_rs1_value=32'd0;
                dispatch_rs1_ready=0;
                //dispatch_rs1_tag=RAT[dec_rs1].tag;
            end
        end
        else begin  //do not use rs1
            //dispatch_fire=0;
            //rob_alloc_fire=0;
            dispatch_rs1_value=32'd0;
            dispatch_rs1_ready=1;
        end
        //rs2
        arf_rs2_addr=dec_rs2;
        dispatch_rs2_tag=RAT[dec_rs2].tag;
        dispatch_rs2_value=32'd0;
        dispatch_rs2_ready=0;
        if(!dec_use_rs2&&dec_rs2_is_imm)begin
            dispatch_rs2_value=dec_imm;
            dispatch_rs2_ready=1;
        end
        else if(dec_use_rs2&&dec_rs2_is_imm==0)begin
            if(dec_rs2==0)begin//rs1 is x0
                dispatch_rs2_value=32'd0;
                dispatch_rs2_ready=1;
            end
            else if(RAT[dec_rs2].valid==0)begin
                //arf_rs2_addr=dec_rs2;
                dispatch_rs2_value=arf_rs2_value;
                dispatch_rs2_ready=1;
            end
            else if(RAT[dec_rs2].valid&&wb_valid&&wb_tag==RAT[dec_rs2].tag)begin
                dispatch_rs2_value=wb_value;
                dispatch_rs2_ready=1;
                //dispatch_rs2_tag=RAT[dec_rs2].tag;
            end
            else if(RAT[dec_rs2].valid&&rob_rs2_ready&&rob_rs2_valid)begin
                dispatch_rs2_value=rob_rs2_value;
                dispatch_rs2_ready=1;
                //dispatch_rs2_tag=RAT[dec_rs2].tag;
            end
            else begin //RAT reflect but rob not ready
                dispatch_rs2_value=32'd0;
                dispatch_rs2_ready=0;
                //dispatch_rs2_tag=RAT[dec_rs2].tag;
            end
        end
        else begin
            dispatch_rs2_value=32'd0;
            dispatch_rs2_ready=1;
        end 
    //    dispatch_fire=1;
    //    rob_alloc_fire=1;
    //
    //    //find rs and rs2 
    //    arf_rs1_addr=dec_rs1;
    //    arf_rs2_addr=dec_rs2;
    //    rob_alloc_reg_write=dec_reg_write;
    //    rob_alloc_pc=dec_pc;
    //    dispatch_alu_control=dec_alu_control;
    //    if(RAT[dec_rs1].valid&&dec_use_rs1)begin
    //        //rob 
    //        //rob_rd=RAT[dec_rs1].tag;
    //        rob_rs1_tag=RAT[dec_rs1].tag;
    //        //inquire and return while this rd get the result(the most new instruction)
    //        dispatch_rs1_tag=RAT[dec_rs1].tag;//rs1_tag  ->  rob tag
    //        if(rob_rs1_valid&&rob_rs1_ready)begin
    //            dispatch_rs1_value=rob_rs1_value;
    //            dispatch_rs1_ready=1;
    //        end
    //        else begin
    //            dispatch_rs1_value=32'd0;
    //            dispatch_rs1_ready=0;
    //        end
    //        //rs
    //        //dispatch_rs1_tag=RAT[dec_rs1].tag;
    //        //dispatch_rs1_ready=0;
    //        //dispatch_rs1_value=0;
    //    end
    //    else begin
    //       //alloc new x(rd) come form this instruction
    //        //RAT[dec_rd].valid=1;
    //        //RAT[dec_rd].tag=rob_alloc_tag;//tag depend on what rob alloc
    //        dispatch_rs1_value=arf_rs1_value;
    //
    //    end
    //
    //    if(RAT[dec_rs2].valid&&dec_use_rs2)begin
    //        rob_rs2_tag=RAT[dec_rs2].tag;
    //        dispatch_rs2_tag=RAT[dec_rs2].tag;//rs1_tag  ->  rob tag
    //        if(rob_rs2_valid&&rob_rs2_ready)begin
    //            dispatch_rs2_value=rob_rs2_value;
    //            dispatch_rs2_ready=1;
    //        end
    //        else begin
    //            dispatch_rs2_value=32'd0;
    //            dispatch_rs2_ready=0;
    //        end
    //    end
    //    else if(!RTA[dec_rs2].valid&&dec_use_rs2) begin
    //        //RAT[dec_rd].valid=1;
    //        //RAT[dec_rd].tag=rob_alloc_tag;
    //        dispatch_rs2_value=arf_rs2_value;
    //    end
    end

    else begin
        dispatch_fire=0;
        rob_alloc_fire=0;

        rob_rs1_tag=3'd0;
        rob_rs2_tag=3'd0;
        dispatch_alu_control=4'd0;
        dispatch_rob_tag=3'd0;
        rob_rd=5'd0;
        rob_alloc_reg_write=0;
        arf_rs1_addr=5'd0;
        arf_rs2_addr=5'd0;
        dispatch_rs1_tag=3'd0;
        dispatch_rs2_tag=3'd0;
        rob_alloc_pc=32'd0;
        dispatch_rs1_value=32'd0;
        dispatch_rs1_ready=0;
        dispatch_rs2_value=32'd0;
        dispatch_rs2_ready=0;
    end

  

    

    
end


always_ff@(posedge clk)begin
    if(!rst_n)begin
        for(int i=0;i<32;i++)begin
            RAT[i].valid<=0;
            RAT[i].tag<=3'd0;    
        end
    end
    else begin
        if(commit_valid&&RAT[commit_rd].tag==commit_tag&&commit_reg_write)begin
            RAT[commit_rd].valid<=0;
        end
        if(dec_valid&&rob_alloc_ready&&rs_alloc_ready&&dec_rd!=5'd0&&dec_reg_write)begin
            RAT[dec_rd].valid<=1;
            RAT[dec_rd].tag<=rob_alloc_tag;

        end
    end
end


endmodule