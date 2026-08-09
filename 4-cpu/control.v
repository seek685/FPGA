/**
opcode	RegWrite	ALUSrc	MemRead	MemWrite	MemtoReg	Branch	ALUOp	ImmSel
0110011	ADD/SUB/AND/OR	1	0	0	0	0	0	10	x
0000011	LW	1	1	1	0	1	0	00	000
0100011	SW	0	1	0	1	0	0	00	001
1100011	BEQ	0	0	0	0	0	1	01	010
**/

module control(
    input  wire [6:0] opcode,

    output reg reg_write, 
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg MemtoReg,
    output reg branch,
    output reg [1:0]alu_op,
    output reg [2:0]imm_sel
);
parameter R_type=7'b0110011;
parameter lw=7'b0000011;
parameter sw=7'b0100011;
parameter beq=7'b1100011;
always@(*) begin
    case(opcode)
    R_type: begin
        reg_write=1'b1;
        alu_src=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=1'b0;
        branch=1'b0;
        alu_op=2'b10;
        imm_sel=3'b000;
    end
    lw: begin
        reg_write=1'b1;
        alu_src=1'b1;
        mem_read=1'b1;
        mem_write=1'b0;
        MemtoReg=1'b1;
        branch=1'b0;
        alu_op=2'b00;
        imm_sel=3'b000;
    end  
    sw:begin
        reg_write=1'b0;
        alu_src=1'b1;
        mem_read=1'b0;
        mem_write=1'b1;
        MemtoReg=1'b0;
        branch=1'b0;
        alu_op=2'b00;
        imm_sel=3'b001;
    end
    beq:begin
        reg_write=1'b0;
        alu_src=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=1'b0;
        branch=1'b1;
        alu_op=2'b01;
        imm_sel=3'b010;
    end
    default:begin
        reg_write=1'b0;
        alu_src=1'b0;
        mem_read=1'b0;
        mem_write=1'b0;
        MemtoReg=1'b0;
        branch=1'b0;
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
        2'b00:alu_control=4'd0;//lw sw
        2'b01:alu_control=4'd1;//beq
        2'b10:begin  //R type
            case(funct3)
            3'b000:alu_control=(funct7_5==1)?4'd1:4'b0000; // ADD/SUB
            3'b111:alu_control=4'b0010; //AND
            3'b110:alu_control=4'b0011;//OR
            default:alu_control=4'b0000;
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
    output wire alu_src,
    output wire mem_read,
    output wire mem_write,
    output wire MemtoReg,
    output wire branch,
    output wire [2:0] imm_sel,
    output wire [3:0] alu_control

);
//only alu_op 
    wire [1:0] alu_op;

    control u_control(
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .MemtoReg(MemtoReg),
        .branch(branch),
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