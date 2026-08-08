`timescale 1ns/1ns
module tb_control;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg funct7_5;

    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire MemtoReg;
    wire branch;
    wire [2:0] imm_sel;
    wire [3:0] alu_control;
    integer errors=0;

    ctrl u_ctrl(
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .MemtoReg(MemtoReg),
        .branch(branch),
        .imm_sel(imm_sel),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .alu_control(alu_control)
    );
    task check;
        input [6:0]      op;      
        input [2:0]      f3;
        input            f7_5;
        input [12:0]     exp;    
        input [8*16-1:0] name;    // 1 ASCII=1byte=8bit  the max length of string=16
        begin
            opcode = op; funct3 = f3; funct7_5 = f7_5;   //dirve
            #10;                                         
            if ({reg_write, alu_src, mem_read, mem_write, MemtoReg, branch, imm_sel, alu_control} !== exp) begin
                $display("ERROR %0s: expect %b, get %b", name, exp,
                         {reg_write, alu_src, mem_read, mem_write, MemtoReg, branch, imm_sel, alu_control});
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check(7'b0110011,3'b000,1'b0,13'b1_0_0_0_0_0_000_0000,"ADD");
        check(7'b0110011,3'b000,1'b1,13'b1_0_0_0_0_0_000_0001,"SUB");
        check(7'b0110011,3'b111,1'b0,13'b1_0_0_0_0_0_000_0010,"AND");
        check(7'b0110011,3'b110,1'b0,13'b1_0_0_0_0_0_000_0011,"OR");

        check(7'b0000011,3'b010,1'b0,13'b1_1_1_0_1_0_000_0000,"LW");
        check(7'b0000011,3'b111,1'b0,13'b1_1_1_0_1_0_000_0000,"LW");//check

        check(7'b0100011,3'b010,1'b0,13'b0_1_0_1_0_0_001_0000,"SW");

        check(7'b1100011,3'b000,1'b0,13'b0_0_0_0_0_1_010_0001,"BEQ");
        check(7'b1100011,3'b111,1'b0,13'b0_0_0_0_0_1_010_0001,"BEQ");//check

        check(7'b1111111,3'b000,1'b0,13'b0_0_0_0_0_0_000_0000,"ILLEGAL");
        check(7'b0110011,3'b010,1'b0,13'b1_0_0_0_0_0_000_0000,"R-SLT");//R type but now in default
        if(errors==0) $display("ALL PASS");
        else    $display("%d Errors",errors);
        $finish;
    end
    
endmodule
