module out_of_order_cpu(
    input logic cpu_clk,
    input logic cpu_rst,
    output logic[31:0] irom_addr,
    input logic[31:0] irom_data,

    output logic[31:0] perip_addr,
    output logic perip_wen,
    output logic [1:0] perip_mask,
    output logic [31:0] perip_wdata,
    input logic[31:0] perip_rdata
);
logic rst_n;
assign rst_n = ~cpu_rst;
logic [31:0] pc;


logic if_id_valid;
logic [31:0] if_id_pc;
logic [31:0] if_id_instr;
logic [31:0] dec_imm;
logic dec_ready;
logic branch;
logic [1:0] jump;
logic mem_write;
logic mem_read;
logic [1:0] MemtoReg;
logic reg_write;
logic [1:0] alu_src_a;
logic alu_src_b;
logic [2:0] imm_sel;
logic [3:0] alu_control;
logic [2:0] kind;
logic use_rs1;
logic use_rs2;

logic rs_issue_valid;
logic [2:0] rs_issue_rob_tag;
logic [3:0] rs_issue_alu_control;
logic [31:0] rs_issue_rs1_value;
logic [31:0] rs_issue_rs2_value;

logic issue_ex_valid;
logic [2:0] issue_ex_rob_tag;
logic [3:0] issue_ex_alu_control;
logic [31:0] issue_ex_rs1_value;
logic [31:0] issue_ex_rs2_value;
logic [2:0] issue_ex_kind;
logic [31:0] issue_ex_pc;
logic [31:0] issue_ex_imm;
logic [2:0] issue_ex_funct3;
logic [1:0] issue_ex_alu_src_a;
logic issue_ex_alu_src_b;

logic [31:0]ex_alu_result;
logic ex_wb_valid;
logic [2:0]ex_wb_rob_tag;
logic [31:0]ex_wb_value;
logic ex_wb_result_valid;
logic [2:0] ex_wb_kind;
logic ex_wb_actual_taken;
logic [31:0] ex_wb_actual_target;
logic [31:0] ex_wb_actual_next_pc;
logic ex_wb_broadcast_valid;
assign ex_wb_broadcast_valid=ex_wb_valid&&ex_wb_result_valid;


logic rob_commit_valid;
logic commit_fire;
logic [2:0]rob_commit_tag;
logic [4:0] rob_commit_rd;
logic rob_commit_reg_write;
logic [31:0] rob_commit_value;
logic [4:0]arf_rs1_addr;
logic [4:0]arf_rs2_addr;
logic [31:0]arf_rs1_value;
logic [31:0]arf_rs2_value;

logic rs_alloc_ready;
logic rob_alloc_ready;
logic dispatch_fire;
logic rob_alloc_fire;
logic [2:0]rob_alloc_tag;
logic [4:0]rob_alloc_rd;
logic rob_alloc_reg_write;
logic [31:0] rob_alloc_pc;
logic [2:0]dispatch_rob_tag;
logic [3:0] dispatch_alu_control;
logic [31:0]dispatch_rs1_value;
logic dispatch_rs1_ready;
logic [2:0] dispatch_rs1_tag;
logic [31:0]dispatch_rs2_value;
logic dispatch_rs2_ready;
logic [2:0] dispatch_rs2_tag;
logic [2:0]rs1_tag;
logic [31:0]rs1_value;
logic rs1_valid;
logic rs1_ready;
logic [2:0]rs2_tag;
logic [31:0]rs2_value;
logic rs2_valid;
logic rs2_ready;

logic [2:0] issue_kind;
logic [31:0] issue_pc;
logic [31:0] issue_imm;
logic [2:0] issue_funct3;
logic [1:0] issue_alu_src_a;
logic issue_alu_src_b;
logic [2:0] dispatch_kind;
logic [31:0] dispatch_pc;
logic [31:0] dispatch_imm;
logic [2:0] dispatch_funct3;
logic [1:0] dispatch_alu_src_a;
logic dispatch_alu_src_b;

logic [2:0]rob_head_tag;

logic [31:0] issue_ex_rs1;
logic [31:0] issue_ex_rs2;

logic [31:0] ex_value;
logic ex_complete_valid;
logic ex_result_valid;
logic ex_actual_taken;
logic [31:0] ex_actual_target;
logic [31:0] ex_actual_next_pc;
logic [31:0] ex_pc_4;
logic [31:0] ex_pc_imm;
logic ex_branch_taken;

// Branch and JAL targets are calculated separately from the ALU operands.

// alu-a  and  alu-b
assign issue_ex_rs1=(issue_ex_alu_src_a==2'b01)?issue_ex_pc:
                        (issue_ex_alu_src_a==2'b10)?32'd0:
                        issue_ex_rs1_value;
assign issue_ex_rs2=(issue_ex_alu_src_b==1)?issue_ex_imm:issue_ex_rs2_value;

assign ex_pc_4=issue_ex_pc+32'd4;
assign ex_pc_imm=issue_ex_pc+issue_ex_imm;

logic access_address_event;
logic ordinary_event;
always_comb begin
    ex_value=32'd0;
    ex_complete_valid=0;
    ex_actual_taken=0;
    ex_result_valid=0;
    ex_actual_target=32'd0;
    ex_actual_next_pc=ex_pc_4;
    //improve:separate 2 event
    access_address_event=0;
    ordinary_event=0;


    case(issue_ex_kind)
        3'd0: begin // I 
            ex_complete_valid=issue_ex_valid;
            ex_result_valid=issue_ex_valid;
            ex_value=ex_alu_result;
            ordinary_event=1;
        end
        3'd1: begin // branch
            ex_complete_valid=issue_ex_valid;
            ex_actual_taken=ex_branch_taken;
            ex_actual_target=ex_pc_imm;
            if(ex_branch_taken) ex_actual_next_pc=ex_pc_imm;
             ordinary_event=1;
        end
        3'd2: begin // JAL
            ex_complete_valid=issue_ex_valid;
            ex_result_valid=issue_ex_valid;
            ex_value=ex_pc_4;
            ex_actual_taken=1;
            ex_actual_target=ex_pc_imm;
            ex_actual_next_pc=ex_pc_imm;
             ordinary_event=1;
        end
        3'd3: begin // JALR
            ex_complete_valid=issue_ex_valid;
            ex_result_valid=issue_ex_valid;
            ex_value=ex_pc_4;
            ex_actual_taken=1;
            ex_actual_target=ex_alu_result&32'hFFFF_FFFE;
            ex_actual_next_pc=ex_alu_result&32'hFFFF_FFFE;
            ordinary_event=1;
        end
        //already add load and store
        3'd4:begin //load
            ex_complete_valid=issue_ex_valid;
            ex_result_valid=issue_ex_valid;
            ex_value=ex_alu_result;//rs1+imm(address)
            ex_actual_taken=1;
            access_address_event=1;
        end
        3'd5:begin//store
            ex_complete_valid=issue_ex_valid;
            ex_result_valid=issue_ex_valid;
            ex_value=ex_alu_result;//rs1+imm(address)
            ex_actual_taken=1;
            ex_actual_target=issue_ex_rs2;//rs2 regarded as write address
            access_address_event=1;
        end
        default: ; // Load and Store wait for their memory path.
    endcase
end




pc u_pc(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .next_pc(next_pc),
    .stall(pc_stall),
    .pc(pc)
);
ctrl U_ctrl(
    .opcode(if_id_instr[6:0]),
    .funct3(if_id_instr[14:12]),
    .funct7_5(if_id_instr[30]),
    .branch(branch),
    .jump(jump),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .MemtoReg(MemtoReg),
    .reg_write(reg_write),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .imm_sel(imm_sel),
    .alu_control(alu_control),
    .kind(kind),
    .use_rs1(use_rs1),
    .use_rs2(use_rs2)
);
immgen U_immgen(
    .instr(if_id_instr),
    .imm_sel(imm_sel),
    .imm(dec_imm)
);
branch_unit u_branch_unit(
    .rdata1(issue_ex_rs1_value),
    .rdata2(issue_ex_rs2_value),
    .funct3(issue_ex_funct3),
    .branch_1(ex_branch_taken)
);
//wb maybe is access_address_event or ordinary_event

rob ROB(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .alloc_kind(dispatch_kind),
    .alloc_ready(rob_alloc_ready),
    .alloc_tag(rob_alloc_tag),
    .alloc_fire(rob_alloc_fire),
    .alloc_rd(rob_alloc_rd),
    .alloc_reg_write(rob_alloc_reg_write),
    .alloc_pc(rob_alloc_pc),
    .rs1_tag(rs1_tag),
    .rs1_valid(rs1_valid),
    .rs1_ready(rs1_ready),
    .rs1_value(rs1_value),
    .rs2_tag(rs2_tag),
    .rs2_valid(rs2_valid),
    .rs2_ready(rs2_ready),
    .rs2_value(rs2_value),
    .wb_tag(ex_wb_rob_tag),
    .wb_valid(ex_wb_valid),
    .wb_value(ex_wb_value),

    .wb_actual_target(ex_wb_actual_target),
    .wb_actual_taken(ex_wb_actual_taken),
    .wb_actual_next_pc(ex_wb_actual_next_pc),
    .mem_prepare_valid(),
    .mem_prepare_tag(),
    .mem_prepare_addr(),
    .mem_prepare_store_data(),
    .head_valid(),
    .head_kind(),
    .head_mem_prepare(),
    .head_mem_addr(),
    .head_store_data(),
    .head_funct3(),


    .commit_ready(1),
    .commit_fire(commit_fire),
    .commit_actual_taken(),
    .commit_actual_target(),
    .commit_actual_next_pc(),

    .commit_valid(rob_commit_valid),
    .commit_tag(rob_commit_tag),
    .commit_rd(rob_commit_rd),
    .commit_reg_write(rob_commit_reg_write),
    .commit_value(rob_commit_value),
    .commit_pc(),
    .head_sent_RS(rob_head_tag)
);
RS rs(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .rs_alloc_ready(rs_alloc_ready),
    .dispatch_fire(dispatch_fire),
    .dispatch_rob_tag(dispatch_rob_tag),
    .dispatch_alu_control(dispatch_alu_control),
    .dispatch_rs1_value(dispatch_rs1_value),
    .dispatch_rs1_ready(dispatch_rs1_ready),
    .dispatch_rs1_tag(dispatch_rs1_tag),
    .dispatch_rs2_value(dispatch_rs2_value),
    .dispatch_rs2_ready(dispatch_rs2_ready),
    .dispatch_rs2_tag(dispatch_rs2_tag),
    .dispatch_kind(dispatch_kind),
    .dispatch_pc(dispatch_pc),
    .dispatch_imm(dispatch_imm),
    .dispatch_funct3(dispatch_funct3),
    .dispatch_alu_src_a(dispatch_alu_src_a),
    .dispatch_alu_src_b(dispatch_alu_src_b),
    .wb_valid(ex_wb_broadcast_valid),
    .wb_tag(ex_wb_rob_tag),
    .wb_value(ex_wb_value),
    .rob_head_tag(rob_head_tag),
    .issue_valid(rs_issue_valid),
    .issue_rob_tag(rs_issue_rob_tag),
    .issue_alu_control(rs_issue_alu_control),
    .issue_rs1_value(rs_issue_rs1_value),
    .issue_rs2_value(rs_issue_rs2_value),

    .issue_kind(issue_kind),
    .issue_pc(issue_pc),
    .issue_imm(issue_imm),
    .issue_funct3(issue_funct3),
    .issue_alu_src_a(issue_alu_src_a),
    .issue_alu_src_b(issue_alu_src_b)
);
rename Rename(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .dec_valid(if_id_valid),
    .dec_ready(dec_ready),
    .dec_kind(kind),
    .dec_funct3(if_id_instr[14:12]),
    .dec_alu_src_a(alu_src_a),
    .dec_alu_src_b(alu_src_b),
    .dec_pc(if_id_pc),
    .dec_imm(dec_imm),
    .dec_rs1(if_id_instr[19:15]),
    .dec_rs2(if_id_instr[24:20]),
    .dec_rd(if_id_instr[11:7]),
    .dec_reg_write(reg_write),
    .dec_alu_control(alu_control),
    .dec_use_rs1(use_rs1),
    .dec_use_rs2(use_rs2),
    .arf_rs1_addr(arf_rs1_addr),
    .arf_rs1_value(arf_rs1_value),
    .arf_rs2_addr(arf_rs2_addr),
    .arf_rs2_value(arf_rs2_value),
    .rob_alloc_ready(rob_alloc_ready),
    .rob_alloc_tag(rob_alloc_tag),
    .rob_alloc_fire(rob_alloc_fire),
    .rob_rd(rob_alloc_rd),
    .rob_alloc_reg_write(rob_alloc_reg_write),
    .rob_alloc_pc(rob_alloc_pc),
    .rob_rs1_tag(rs1_tag),
    .rob_rs1_valid(rs1_valid),
    .rob_rs1_ready(rs1_ready),
    .rob_rs1_value(rs1_value),
    .rob_rs2_tag(rs2_tag),
    .rob_rs2_valid(rs2_valid),
    .rob_rs2_ready(rs2_ready),
    .rob_rs2_value(rs2_value),
    .rs_alloc_ready(rs_alloc_ready),
    .dispatch_fire(dispatch_fire),
    .dispatch_rob_tag(dispatch_rob_tag),
    .dispatch_alu_control(dispatch_alu_control),
    .dispatch_rs1_value(dispatch_rs1_value),
    .dispatch_rs1_ready(dispatch_rs1_ready),
    .dispatch_rs1_tag(dispatch_rs1_tag),
    .dispatch_rs2_value(dispatch_rs2_value),
    .dispatch_rs2_ready(dispatch_rs2_ready),
    .dispatch_rs2_tag(dispatch_rs2_tag),

    .dispatch_kind(dispatch_kind),
    .dispatch_pc(dispatch_pc),
    .dispatch_imm(dispatch_imm),
    .dispatch_funct3(dispatch_funct3),
    .dispatch_alu_src_a(dispatch_alu_src_a),
    .dispatch_alu_src_b(dispatch_alu_src_b),

    .wb_valid(ex_wb_broadcast_valid),
    .wb_tag(ex_wb_rob_tag),
    .wb_value(ex_wb_value),
    //.commit_valid(rob_commit_valid),
    .commit_valid(commit_fire),
    .commit_tag(rob_commit_tag),
    .commit_rd(rob_commit_rd),
    .commit_reg_write(rob_commit_reg_write)
);
issue_ex u_issue_ex(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .in_valid(rs_issue_valid),
    .in_rob_tag(rs_issue_rob_tag),
    .in_alu_control(rs_issue_alu_control),
    .in_rs1_value(rs_issue_rs1_value),
    .in_rs2_value(rs_issue_rs2_value),
    .out_valid(issue_ex_valid),
    .out_rob_tag(issue_ex_rob_tag),
    .out_alu_control(issue_ex_alu_control),
    .out_rs1_value(issue_ex_rs1_value),
    .out_rs2_value(issue_ex_rs2_value),

    .in_kind(issue_kind),
    .in_pc(issue_pc),
    .in_imm(issue_imm),
    .in_funct3(issue_funct3),
    .in_alu_src_a(issue_alu_src_a),
    .in_alu_src_b(issue_alu_src_b),
    .out_kind(issue_ex_kind),
    .out_pc(issue_ex_pc),
    .out_imm(issue_ex_imm),
    .out_funct3(issue_ex_funct3),
    .out_alu_src_a(issue_ex_alu_src_a),
    .out_alu_src_b(issue_ex_alu_src_b)

);
alu ALU(
    .a(issue_ex_rs1),
    .b(issue_ex_rs2),
    .alu_control(issue_ex_alu_control),
    .alu_result(ex_alu_result)
);
ex_wb u_ex_wb(
    .clk(cpu_clk),
    .rst_n(rst_n),
    //.in_valid(ex_complete_valid),
    .in_valid(),//wb_valid
    .in_rob_tag(issue_ex_rob_tag),
    .in_value(ex_value),
    .in_result_valid(ex_result_valid),
    .in_kind(issue_ex_kind),
    .in_actual_taken(ex_actual_taken),
    .in_actual_target(ex_actual_target),
    .in_actual_next_pc(ex_actual_next_pc),
    .out_valid(ex_wb_valid),
    .out_rob_tag(ex_wb_rob_tag),
    .out_value(ex_wb_value),
    .out_result_valid(ex_wb_result_valid),
    .out_kind(ex_wb_kind),
    .out_actual_taken(ex_wb_actual_taken),
    .out_actual_target(ex_wb_actual_target),
    .out_actual_next_pc(ex_wb_actual_next_pc)
);
regfile u_regfile(
    .raddr1(arf_rs1_addr),
    .raddr2(arf_rs2_addr),
    .waddr(rob_commit_rd),
    .we(commit_fire&&rob_commit_reg_write),
    .clk(cpu_clk),
    .rst_n(rst_n),
    .wdata(rob_commit_value),
    .rdata1(arf_rs1_value),
    .rdata2(arf_rs2_value)
    );


endmodule
