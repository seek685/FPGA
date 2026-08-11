module imem(
    input wire [31:0] pc,

    output wire [31:0] instr
// output wire [6:0] opcode,
// output wire [4:0] rs1,
// output wire [4:0] rs2,
// output wire [4:0] rd,
// output wire [2:0] funct3,
// output wire funct7_5
);
    reg [31:0] imem [0:255];
    
    assign instr=imem[(pc-32'h8000_0000)>>2];//0x8000_0000-index 0
 // assign opcode=instr[6:0];
 // assign rs1=instr[19:15];
 // assign rs2=instr[24:20];
 // assign rd=instr[11:7];
 // assign funct3=instr[14:12];
 // assign funct7_5=instr[30];
    initial begin
    $readmemh("program.hex", imem);
end
endmodule