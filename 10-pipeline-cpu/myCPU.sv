module myCPU(
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
    logic stall;
    logic flush;
    logic if_id_valid;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_pc4;
    logic [31:0] if_id_instr;

    logic id_ex_valid;
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_pc4;
    logic [31:0] id_ex_rs1_value;
    logic [31:0] id_ex_rs2_value;
    logic [31:0] id_ex_imm;
    logic [4:0] id_ex_rs1;
    logic [4:0] id_ex_rs2;
    logic [4:0] id_ex_rd;
    logic [2:0] id_ex_funct3;
    logic id_ex_funct7_5;
    logic [1:0] id_ex_alu_src_a;
    logic id_ex_alu_src_b;
    logic [3:0] id_ex_alu_control;
    logic id_ex_reg_write;
    logic id_ex_mem_read;
    logic id_ex_mem_write;
    logic [1:0] id_ex_MemtoReg;
    logic id_ex_branch;
    logic [1:0] id_ex_jump;
    logic [1:0]id_ex_mem_size;
    logic id_ex_load_unsigned;
    
    logic ex_mem_valid;
    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_store_data;//mem_wdata
    logic [31:0] ex_mem_pc4;
    logic [4:0] ex_mem_rd;
    logic ex_mem_reg_write;
    logic ex_mem_mem_read;
    logic ex_mem_mem_write;
    logic [1:0] ex_mem_MemtoReg;
    logic [1:0] ex_mem_mem_size;
    logic ex_mem_load_unsigned;
    
    logic rst_n;
    assign rst_n = ~cpu_rst;
    //pc
    logic [31:0] pc;
    logic [31:0] next_pc;
    logic [31:0] pc_4;
    logic [31:0] pc_imm;
    //alu
    logic [31:0] b;
    logic [31:0] a;
    //logic zero;
    logic [31:0] alu_result;

    //ctrl
    logic reg_write;
    logic [1:0] alu_src_a;
    logic alu_src_b;
    logic mem_read;
    logic mem_write;
    logic [1:0] MemtoReg;
    logic branch;
    logic [1:0] jump;
    logic [2:0] imm_sel;
    logic [3:0] alu_control;

    assign irom_addr=pc;
    logic [31:0] instr;
    assign instr = irom_data;

    //regfile
    logic [31:0] rdata1;
    logic [31:0] rdata2;

    //immgen
    logic [31:0] imm;

    //branch_unit
    logic branch_1;

    //AND
    logic pc_src;
    assign pc_src=branch&branch_1;
    //pc_4
    assign pc_4=pc+32'd4;

    //pc_imm
    assign pc_imm=id_ex_pc+id_ex_imm;

    //pc_src MUX
    assign next_pc=pc_4;
    //(jump==2'b10)?{alu_result[31:1],1'b0}://jalr
    //               (jump==2'b01)?pc_imm:  //jal
    //               (pc_src==1'b1)?pc_imm:  //b_type
    //                               pc_4;   //normal

    //alu_src MUX
    //running while ex
    assign b=(id_ex_alu_src_b==1)?id_ex_imm:id_ex_rs2_value;
    assign a = (id_ex_alu_src_a==2'b01) ? id_ex_pc:
               (id_ex_alu_src_a==2'b10) ? 32'd0:
                                    id_ex_rs1_value;//case00 and case 11 as default

    assign perip_addr  = ex_mem_alu_result;
    assign perip_wdata = ex_mem_store_data;
    assign perip_wen   = ex_mem_valid&&ex_mem_mem_write;
    assign perip_mask  = ex_mem_mem_size;    // funct3 low2

    logic [31:0] read_data;
    always_comb begin
        case (instr[14:12])
            3'b000: read_data = {{24{perip_rdata[7]}}, perip_rdata[7:0]};
            3'b001: read_data = {{16{perip_rdata[15]}}, perip_rdata[15:0]};
            default: read_data = perip_rdata; // LW, LBU, LHU
        endcase
    end
    //MemtoReg
    logic [31:0] write_back;
    assign write_back=(MemtoReg==2'b01)?read_data:
                      (MemtoReg==2'b10)?pc_4:
                                        alu_result;//case 00 and case 11 as default

    pc u_pc(
        .clk(cpu_clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(pc)
    );
    alu u_alu(
        .a(a),
        .b(b),
        .alu_control(id_ex_alu_control),
        .alu_result(alu_result)
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
        .alu_control(alu_control)
    );
    regfile u_regfile(
        .raddr1(if_id_instr[19:15]),
        .raddr2(if_id_instr[24:20]),
        .waddr(if_id_instr[11:7]),
        .we(1'b0),
        .clk(cpu_clk),
        .wdata(write_back),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );
    immgen u_immgen(
        .instr(if_id_instr),
        .imm_sel(imm_sel),
        .imm(imm)
    );
    branch_unit u_branch_unit(
        .rdata1(rdata1),
        .rdata2(rdata2),
        .funct3(if_id_instr[14:12]),
        .branch_1(branch_1)
    );
    if_id u_if_id(
        .clk(cpu_clk),
        .rst(rst_n),
        .flush(1'b0),
        .stall(1'b0),
        .in_valid(1'b1),
        .in_pc(pc),
        .in_pc4(pc_4),
        .in_instr(irom_data),
        .out_valid(if_id_valid),
        .out_pc(if_id_pc),
        .out_pc4(if_id_pc4),
        .out_instr(if_id_instr)
    );
    id_ex u_id_ex(
        .clk(cpu_clk),
        .rst_n(rst_n),
        .flush(1'b0),
        .bubble(1'b0),
        .in_valid(if_id_valid),
        .in_pc(if_id_pc),
        .in_pc4(if_id_pc4),
        .in_rs1_value(rdata1),
        .in_rs2_value(rdata2),
        .in_imm(imm),
        .in_rs1(if_id_instr[19:15]),
        .in_rs2(if_id_instr[24:20]),
        .in_rd(if_id_instr[11:7]),
        .in_funct3(if_id_instr[14:12]),
        .in_funct7_5(if_id_instr[30]),
        .in_alu_src_a(alu_src_a),
        .in_alu_src_b(alu_src_b),
        .in_alu_control(alu_control),
        .in_reg_write(reg_write),
        .in_mem_read(mem_read),
        .in_mem_write(mem_write),
        .in_MemtoReg(MemtoReg),
        .in_branch(branch),
        .in_jump(jump),
        .in_mem_size(2'b00),
        .in_load_unsigned(1'b0),

        .out_valid(id_ex_valid),
        .out_pc(id_ex_pc),
        .out_pc4(id_ex_pc4),
        .out_rs1_value(id_ex_rs1_value),
        .out_rs2_value(id_ex_rs2_value),
        .out_imm(id_ex_imm),
        .out_rs1(id_ex_rs1),
        .out_rs2(id_ex_rs2),
        .out_rd(id_ex_rd),
        .out_funct3(id_ex_funct3),
        .out_funct7_5(id_ex_funct7_5),
        .out_alu_src_a(id_ex_alu_src_a),
        .out_alu_src_b(id_ex_alu_src_b),
        .out_alu_control(id_ex_alu_control),
        .out_reg_write(id_ex_reg_write),
        .out_mem_read(id_ex_mem_read),
        .out_mem_write(id_ex_mem_write),
        .out_MemtoReg(id_ex_MemtoReg),
        .out_branch(id_ex_branch),
        .out_jump(id_ex_jump),
        .out_mem_size(id_ex_mem_size),
        .out_load_unsigned(id_ex_load_unsigned)
    );
    ex_mem u_ex_mem(
        .clk(cpu_clk),
        .rst_n(rst_n),
        .flush(1'b0),
        .bubble(1'b0),
        .in_valid(id_ex_valid),
        .in_alu_result(alu_result),
        .in_store_data(id_ex_rs2_value),
        .in_pc4(id_ex_pc4),
        .in_rd(id_ex_rd),
        .in_reg_write(id_ex_reg_write),
        .in_mem_read(id_ex_mem_read),
        .in_mem_write(id_ex_mem_write),
        .in_MemtoReg(id_ex_MemtoReg),
        .in_mem_size(id_ex_mem_size),
        .in_load_unsigned(id_ex_load_unsigned),

        .out_valid(ex_mem_valid),
        .out_alu_result(ex_mem_alu_result),
        .out_store_data(ex_mem_store_data),
        .out_pc4(ex_mem_pc4),
        .out_rd(ex_mem_rd),
        .out_reg_write(ex_mem_reg_write),
        .out_mem_read(ex_mem_mem_read),
        .out_mem_write(ex_mem_mem_write),
        .out_MemtoReg(ex_mem_MemtoReg),
        .out_mem_size(ex_mem_mem_size),
        .out_load_unsigned(ex_mem_load_unsigned)

    );

endmodule
