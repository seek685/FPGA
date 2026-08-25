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
    assign pc_imm=pc+imm;

    //pc_src MUX
    assign next_pc=
    //(jump==2'b10)?{alu_result[31:1],1'b0}://jalr
    //               (jump==2'b01)?pc_imm:  //jal
    //               (pc_src==1'b1)?pc_imm:  //b_type
    //                               pc_4;   //normal

    //alu_src MUX
    assign b=(alu_src_b==1)?imm:rdata2;
    assign a = (alu_src_a==2'b01) ? pc:
               (alu_src_a==2'b10) ? 32'd0:
                                    rdata1;//case00 and case 11 as default
                                    
    assign perip_addr  = alu_result;   
    assign perip_wdata = rdata2;       
    assign perip_wen   = mem_write;
    assign perip_mask  = instr[13:12];    // funct3 low2

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

   // dmem u_dmem(
   //     .mem_write(mem_write),
   //     .mem_read(mem_read),
   //     .clk(clk),
   //     .mem_wdata(rdata2),
   //     .addr(alu_result),
   //     .funct3(instr[14:12]),
   //     .read_data(read_data)
//
 //   );
//   imem u_imem(
//       .pc(irom_addr),
//       .instr(instr)
//   );
    regfile u_regfile(
        .raddr1(instr[19:15]),
        .raddr2(instr[24:20]),
        .waddr(instr[11:7]),
        .we(reg_write),
        .clk(cpu_clk),
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
