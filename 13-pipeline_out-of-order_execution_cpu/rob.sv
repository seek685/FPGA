module rob(
    input logic clk,
    input logic rst_n,
    //rename
    output logic alloc_ready,
    output logic [2:0] alloc_tag,
    input logic alloc_fire,
    input logic [4:0] alloc_rd,
    input logic alloc_reg_write,
    input logic [31:0] alloc_pc,
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
    input logic [2:0] wb_tag,
    input logic wb_valid,
    input logic [31:0] wb_value,
    //commit
    output logic commit_valid,
    output logic [2:0] commit_tag,
    output logic [4:0] commit_rd,
    output logic commit_reg_write,
    output logic [31:0] commit_value,
    output logic [31:0] commit_pc,

    output logic [2:0] head_sent_RS
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
        if(ROB[head].ready==1 && ROB[head].valid==1 &&count!=0)begin
            commit_valid=1;
            commit_tag=head;
            commit_rd=ROB[head].rd;
            commit_reg_write=ROB[head].reg_write;
            commit_value=ROB[head].value;
            commit_pc=ROB[head].pc;
        end else commit_valid=0;

        alloc_ready=0;
        alloc_tag=3'd0;
        if(count<4'd8)begin
            alloc_ready=1;
            alloc_tag=tail;
        end
        else if(count==4'd8&&commit_valid==1)begin
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
        else begin
            //commit
            if(commit_valid==1)begin
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
                //alloc_tag<=tail;
                tail<=tail+3'd1;
                //alloc_ready<=1'b1;
            end
            if(wb_valid)begin
                ROB[wb_tag].value<=wb_value;
                ROB[wb_tag].ready<=1'b1;
            end

            if(alloc_fire==0&&commit_valid==1)begin
                count<=count-4'd1;
            end
            else if(commit_valid==0&&alloc_fire==1)begin
                count<=count+4'd1;
            end
        end
    end
endmodule