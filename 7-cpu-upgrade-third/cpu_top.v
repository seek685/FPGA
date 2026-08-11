module cpu_top(
    input wire clk,
    input wire rst_n
);
    //pc
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_4;
    wire [31:0] pc_imm;
    //alu
    wire [31:0] b;
    wire [31:0] a;
    //wire zero;
    wire [31:0] alu_result;

    //ctrl
    wire reg_write;
    wire [1:0] alu_src_a;
    wire alu_src_b;
    wire mem_read;
    wire mem_write;
    wire [1:0] MemtoReg;
    wire branch;
    wire [1:0] jump;
    wire [2:0] imm_sel;
    wire [3:0] alu_control;

    //dmem
    wire [31:0] read_data;
    
    //imem
    wire [31:0] instr;

    //regfile
    wire [31:0] rdata1;
    wire [31:0] rdata2;

    //immgen
    wire [31:0] imm;

    //branch_unit
    wire branch_1;

    //AND
    wire pc_src;
    assign pc_src=branch&branch_1;
    //pc_4
    assign pc_4=pc+32'd4;

    //pc_imm
    assign pc_imm=pc+imm;

    //pc_src MUX
    assign next_pc=(jump==2'b10)?{alu_result[31:1],1'b0}:
                   (jump==2'b01)?pc_imm:
                   (pc_src==1'b1)?pc_imm:
                                   pc_4;

    //alu_src MUX
    assign b=(alu_src_b==1)?imm:rdata2;
    assign a = (alu_src_a==2'b01) ? pc:
               (alu_src_a==2'b10) ? 32'd0:
                                    rdata1;//case00 and case 11 as default
    //MemtoReg
    wire [31:0] write_back;
    assign write_back=(MemtoReg==2'b01)?read_data:
                      (MemtoReg==2'b10)?pc_4:
                                        alu_result;//case 00 and case 11 as default

    pc u_pc(
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(pc)
    );
    ALU u_ALU(
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .alu_result(alu_result)
        //.zero(zero)
    ); 
    ctrl U_ctrl(
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7_5(instr[30]),
        .branch(branch),
        .jump(jump),
        //.alu_op(alu_op),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .MemtoReg(MemtoReg),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .imm_sel(imm_sel),
        .alu_control(alu_control)
    );
    dmem u_dmem(
        .mem_write(mem_write),
        .mem_read(mem_read),
        .clk(clk),
        .mem_wdata(rdata2),
        .addr(alu_result),
        .read_data(read_data)

    );
    imem u_imem(
        .pc(pc),
        .instr(instr)
    );
    regfile u_regfile(
        .raddr1(instr[19:15]),
        .raddr2(instr[24:20]),
        .waddr(instr[11:7]),
        .we(reg_write),
        .clk(clk),
        .wdata(write_back),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );
    immgen u_immgen(
        .instr(instr),
        .imm_sel(imm_sel),
        .imm(imm)
    );
    branch_unit u_branch_unit(
        .rdata1(rdata1),
        .rdata2(rdata2),
        .funct3(instr[14:12]),
        .branch_1(branch_1)
    );
endmodule
