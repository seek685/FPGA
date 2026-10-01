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

logic [31:0]ex_alu_result;
logic ex_wb_valid;
logic [2:0]ex_wb_rob_tag;
logic [31:0]ex_wb_alu_result;

logic rob_commit_valid;
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


logic [2:0]rob_head_tag;


rob ROB(
    .clk(cpu_clk),
    .rst_n(rst_n),
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
    .wb_value(ex_wb_alu_result),
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
    .wb_valid(ex_wb_valid),
    .wb_tag(ex_wb_rob_tag),
    .wb_value(ex_wb_alu_result),
    .rob_head_tag(rob_head_tag),
    .issue_valid(rs_issue_valid),
    .issue_rob_tag(rs_issue_rob_tag),
    .issue_alu_control(rs_issue_alu_control),
    .issue_rs1_value(rs_issue_rs1_value),
    .issue_rs2_value(rs_issue_rs2_value)
);
rename Rename(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .dec_valid(),
    .dec_ready(),
    .dec_pc(),
    .dec_imm(),
    .dec_rs1(),
    .dec_rs2(),
    .dec_rd(),
    .dec_reg_write(),
    .dec_alu_control(),
    .dec_use_rs1(),
    .dec_use_rs2(),
    .dec_rs1_is_pc(),
    .dec_rs2_is_imm(),
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
    .wb_valid(ex_wb_valid),
    .wb_tag(ex_wb_rob_tag),
    .wb_value(ex_wb_alu_result),
    .commit_valid(rob_commit_valid),
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
    .out_rs2_value(issue_ex_rs2_value)
);
ex_wb u_ex_wb(
    .clk(cpu_clk),
    .rst_n(rst_n),
    .in_valid(issue_ex_valid),
    .in_rob_tag(issue_ex_rob_tag),
    .in_value(ex_alu_result),
    .out_valid(ex_wb_valid),
    .out_rob_tag(ex_wb_rob_tag),
    .out_value(ex_wb_alu_result)
);
regfile u_regfile(
        .raddr1(arf_rs1_addr),
        .raddr2(arf_rs2_addr),
        .waddr(rob_commit_rd),
        .we(rob_commit_valid&&rob_commit_reg_write),
        .clk(cpu_clk),
        .rst_n(rst_n),
        .wdata(rob_commit_value),
        .rdata1(arf_rs1_value),
        .rdata2(arf_rs2_value)
    );
alu ALU(
    .a(issue_ex_rs1_value),
    .b(issue_ex_rs2_value),
    .alu_control(issue_ex_alu_control),
    .alu_result(ex_alu_result)
);

endmodule