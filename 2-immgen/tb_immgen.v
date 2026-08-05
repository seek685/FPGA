`timescale 1ns/1ns
module tb_immgen;
reg [31:0] instr;
reg [2:0] imm_sel;
wire [31:0] imm;
integer errors=0;
immgen u_immgen(
    .instr(instr),
    .imm_sel(imm_sel),
    .imm(imm)
);

initial begin
    errors=0;
    //lw x5,16(x6)  lw(opcode = 0000011，funct3 = 010)
    //imm[11:0] (12b) | rs1 (5b) | funct3 (3b) | rd (5b) | opcode (7b)
    instr={12'd16,5'd6,3'b010,5'd5,7'b0000_011};
    imm_sel=3'b000;
    #10;
    if(imm!==32'h0000_0010) begin
        $display("+I instructions fail,imm=%h,expect 32'h0000_0010",imm);
        errors=errors+1;
    end else $display("+I instruction PASS");
    //lw x5,-8(x6)
    instr={12'b1111_1111_1000,5'd6,3'b010,5'd5,7'b0000_011};
    #10;
    if(imm!==32'hFFFF_FFF8) begin
        $display("-I instructions fail,imm=%h,expect 32'hFFFF_FFF8",imm);
        errors=errors+1;
    end else $display("-I instruction PASS");

    //sw x5,16(x6) sw(opcode = 0100011，funct3 = 010)
    //imm[11:5] (7b) | rs2 (5b) | rs1 (5b) | funct3 (3b) | imm[4:0] (5b) | opcode (7b)
    instr={7'd0,5'd5,5'd6,3'b010,5'd16,7'b0100011};
    imm_sel=3'b001;
    #10;
    if(imm!==32'h0000_0010) begin
        $display("+S instructions fail,imm=%h,expect 32'h0000_0010",imm);
        errors=errors+1;
    end else $display("+S instruction PASS");
    //sw x5,-4(x6)
    instr={7'b111_1111,5'd5,5'd6,3'b010,5'b1_1100,7'b0100011};
    #10;
    if(imm!==32'hFFFF_FFFC) begin
        $display("-S instructions fail,imm=%h,expect 32'hFFFF_FFFC",imm);
        errors=errors+1;
    end else $display("-S instruction PASS");

    //beq x1,x2,+16 beq(opcode = 1100011，funct3 = 000)
    //imm[12] (1b)|imm[10:5](6b)|rs2(5b)|rs1(5b)|funct3(3b)| imm[4:1](4b)| imm[11](1b)| opcode(7b)
    instr={1'b0,6'b00_0000,5'd2,5'd1,3'b000,4'b1000,1'b0,7'b1100011};
    imm_sel=3'b010;
    #10;
    if(imm!==32'h0000_0010) begin
        $display("+B instructions fail,imm=%h,expect 32'h0000_0010",imm);
        errors=errors+1;
    end else $display("+B instruction PASS");
    //beq x1,x2,-8
    instr={1'b1,6'b11_1111,5'd2,5'd1,3'b000,4'b1100,1'b1,7'b1100011};
    #10;
    if(imm!==32'hFFFF_FFF8) begin
        $display("-B instructions fail,imm=%h,expect 32'hFFFF_FFF8",imm);
        errors=errors+1;
    end else $display("-B instruction PASS");

    //lui x5,0x12345  lui(opcode = 0110111)
    //imm[31:12] (20b) | rd (5b) | opcode (7b)
    instr={20'h12345,5'd5,7'b0110111};
    imm_sel=3'b011;
    #10;
    if(imm!==32'h1234_5000) begin
        $display("lui instructions fail,imm=%h,expect 32'h1234_5000",imm);
        errors=errors+1;
    end else $display("lui instruction PASS");

    //jal x1,+2048  jal(opcode = 1101111)
    //imm[20](1b)|imm[10:1](10b)|imm[11](1b)|imm[19:12](8b)|rd(5b)|opcode(7b)
    instr={1'b0,10'b00_0000_0000,1'b1,8'h00,5'd1,7'b1101111};
    imm_sel=3'b100;
    #10;
    if(imm!==32'h0000_0800) begin
        $display("+J instructions fail,imm=%h,expect 32'h0000_0800",imm);
        errors=errors+1;
    end else $display("+J instruction PASS");
    //jal x1,-2048
    instr={1'b1,10'b00_0000_0000,1'b1,8'hFF,5'd1,7'b1101111};
    #10;
    if(imm!==32'hFFFF_F800) begin
        $display("-J instructions fail,imm=%h,expect 32'hFFFF_F800",imm);
        errors=errors+1;
    end else $display("-J instruction PASS");

    imm_sel=3'b111;
    #10;
    if(imm!==32'h0000_0000) begin
        $display("default situation fail,imm=%h,expect 32'h0000_0000",imm);
        errors=errors+1;
    end else $display("default PASS");

    if(errors==0) begin
        $display("ALL PASS");
    end else $display("%d Errors",errors);

    $finish;
end
endmodule
