/**
opcode   type   RegWrite ALUSrcA ALUSrcB MemRead MemWrite MemtoReg Branch Jump ALUOp ImmSel
1101111  jal    1        00      0       0       0        10       0      01   00    100
1100111  jalr   1        00      1       0       0        10       0      10   00    000
**/
module control(
    input  wire [6:0] opcode,

    output reg reg_write, 
    output reg [1:0] alu_src_a,
    output reg alu_src_b,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0]MemtoReg,
    output reg branch,
    output reg [1:0] jump,
    output reg [1:0]alu_op,
    output reg [2:0]imm_sel

);
parameter R_type=7'b0110011;
parameter lw=7'b0000011;
parameter sw=7'b0100011;
parameter B_type=7'b1100011;
parameter I_type=7'b0010011;
parameter lui=7'b0110111;
parameter auipc=7'b0010111;
parameter jal=7'b1101111;
parameter jalr=7'b1100111;
always@(*) begin
    case(opcode)
    R_type: begin
        reg_write=1'b1;
        alu_src_a=2'b00;
        alu_src_b=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b10;
        imm_sel=3'b000;
    end
    lw: begin
        reg_write=1'b1;
        alu_src_a=2'b00;
        alu_src_b=1'b1;
        mem_read=1'b1;
        mem_write=1'b0;
        MemtoReg=2'b01;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b00;
        imm_sel=3'b000;
    end  
    sw:begin
        reg_write=1'b0;
        alu_src_a=2'b00;
        alu_src_b=1'b1;
        mem_read=1'b0;
        mem_write=1'b1;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b00;
        imm_sel=3'b001;
    end
    B_type:begin
        reg_write=1'b0;
        alu_src_a=2'b00;
        alu_src_b=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b1;
        jump=2'b00;
        alu_op=2'b01;
        imm_sel=3'b010;
    end
    I_type:begin
        reg_write=1'b1;
        alu_src_a=2'b00;
        alu_src_b=1'b1;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b11;
        imm_sel=3'b000;
    end
    lui:begin
        reg_write=1'b1;
        alu_src_a=2'b10;
        alu_src_b=1'b1;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b00;
        imm_sel=3'b011;
    end
    auipc:begin
        reg_write=1'b1;
        alu_src_a=2'b01;
        alu_src_b=1'b1;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b00;
        imm_sel=3'b011;
    end
    jal:begin
        reg_write=1'b1;
        alu_src_a=2'b00;
        alu_src_b=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b10;
        branch=1'b0;
        jump=2'b01;
        alu_op=2'b00;
        imm_sel=3'b100;
    end
    jalr:begin
        reg_write=1'b1;
        alu_src_a=2'b00;
        alu_src_b=1'b1;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b10;
        branch=1'b0;
        jump=2'b10;
        alu_op=2'b00;
        imm_sel=3'b000;
    end
    default:begin
        reg_write=1'b0;
        alu_src_a=2'b00;
        alu_src_b=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=2'b00;
        branch=1'b0;
        jump=2'b00;
        alu_op=2'b00;
        imm_sel=3'b000;
    end
    endcase
end
endmodule


module alu_decoder(
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire funct7_5,

    output reg [3:0] alu_control
);
always@(*) begin
    case(alu_op)  //lw sw beq out of control of funct3 and funct7_5
        2'b00:alu_control=4'd0;//lw sw lui auipc
        2'b01:alu_control=4'd1;//beq(replaced it with branch_uint)(deserted)
        2'b10:begin  //R type
            case(funct3)
            3'b000:alu_control=(funct7_5==1)?4'd1:4'b0000; // ADD/SUB
            3'b001:alu_control=4'b0111;//sll
            3'b010:alu_control=4'b0100;//slt
            3'b011:alu_control=4'b0101;//sltu
            3'b100:alu_control=4'b0110;//xor
            3'b101:alu_control=(funct7_5==1)?4'b1001:4'b1000;//1:sra,0:srl
            3'b111:alu_control=4'b0010; //AND
            3'b110:alu_control=4'b0011;//OR
            default:alu_control=4'b0000;
            endcase
        end
        //R'b=rs2  I'b=imm
        2'b11:begin  //I_type
            case(funct3)
            3'b000: alu_control = 4'b0000;// ADDI
            3'b001: alu_control = 4'b0111;// slli
            3'b010: alu_control = 4'b0100;// slti
            3'b011: alu_control = 4'b0101;// sltiu
            3'b100: alu_control = 4'b0110;//xori
            3'b101: alu_control = (funct7_5==1) ? 4'b1001: 4'b1000;//srai/srli                                               
            3'b110: alu_control = 4'b0011;// ORI
            3'b111: alu_control = 4'b0010;// ANDI
            default: alu_control = 4'b0000;
            endcase
        end
        default:alu_control=4'b0000; 
    endcase
end
endmodule

module ctrl(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire funct7_5,

    output wire reg_write,
    output wire [1:0] alu_src_a,
    output wire alu_src_b,
    output wire mem_read,
    output wire mem_write,
    output wire [1:0]MemtoReg,
    output wire branch,
    output wire [1:0] jump,
    output wire [2:0] imm_sel,
    output wire [3:0] alu_control

);
//only alu_op 
    wire [1:0] alu_op;

    control u_control(
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src_b(alu_src_b),
        .alu_src_a(alu_src_a),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .MemtoReg(MemtoReg),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op),
        .imm_sel(imm_sel)
    );
    alu_decoder u_alu_decoder(
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .alu_control(alu_control)
    );

endmodule
