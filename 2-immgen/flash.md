各指令的分段和立即数的分布
//lw x5,16(x6) 
lw(opcode = 0000011，funct3 = 010)
//imm[11:0] (12b) | rs1 (5b) | funct3 (3b) | rd (5b) |opcode (7b)

sw x5,16(x6)
sw(opcode = 0100011，funct3 = 010)
//imm[11:5] (7b) | rs2 (5b) | rs1 (5b) | funct3 (3b) | imm[4:0] (5b) | opcode (7b)

 //beq x1,x2,-8
beq(opcode = 1100011，funct3 = 000)
//imm[12] (1b)|imm[10:5](6b)|rs2(5b)|rs1(5b)|funct3(3b)| imm[4:1](4b)| imm[11](1b)| opcode(7b)

//lui x5,0x12345
lui(opcode = 0110111)
//imm[31:12] (20b) | rd (5b) | opcode (7b)
    
//jal x1,+2048  jal(opcode = 1101111)
//imm[20](1b)|imm[10:1](10b)|imm[11](1b)|imm[19:12](8b)|rd(5b)|opcode(7b)

指令的立即数拼接
控制信号决定是什么指令
    I:imm={{20{instr[31]}},instr[31:20]};
    S:imm={{20{instr[31]}},instr[31:25],instr[11:7]};     B:imm={{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
    U:imm={instr[31:12],12'b0};
    J:imm={{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
    default:imm=32'b0;

imm_sel------->
parameter I=3'b000;
parameter S=3'b001;
parameter B=3'b010;
parameter U=3'b011;
parameter J=3'b100;

拼接问题
正确：{{12{str[31:20]}},20'd0}
错误：{12{str[31:20]},20'd0}