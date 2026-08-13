module immgen(
    input wire [31:0] instr,
    input wire [2:0] imm_sel,
    output reg [31:0] imm
    //000-I 001-S 010-B 011-U 100-J 
);
parameter I=3'b000;
parameter S=3'b001;
parameter B=3'b010;
parameter U=3'b011;
parameter J=3'b100;

    always@(*)begin
        case(imm_sel)
            I:imm={{20{instr[31]}},instr[31:20]};
            S:imm={{20{instr[31]}},instr[31:25],instr[11:7]};
            B:imm={{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
            U:imm={instr[31:12],12'b0};
            J:imm={{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
            default:imm=32'b0;
        endcase
    end
endmodule