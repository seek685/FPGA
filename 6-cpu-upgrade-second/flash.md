vlog pc.v imem.v dmem.v regfile.v ALU.v immgen.v control.v branch_unit.v cpu_top.v
vsim -c -do "quit" work.cpu_top
第一条是编译的命令
第二条是查看端口对接 有没有错误 有没有连线好
imem.v 里 的`$readmemh("program.hex", imem)` 在仿真 0 时刻把文件加载进指令存储器，相当于烧进 ROM 的固件。文件空 = imem 全 X = CPU 空转。当前还不支持lui等立即数加载的指令 需要往dmem里面填入几个数据用lw加载出来
对于imem 地址pc减去基地址之后 imem从0索引开始
而后续读dmem的读地址这时候已经是准确地址 直接右移2即可对应上索引

first：新增了I型指令的支持 以及完善了R型指令 
顺便手搓了几行测试的汇编指令以及机器码 通过仿真查看波形对比没有问题
I型指令和R型指令 
SLL/SRL/SRA/ADD/SLT/SLTU/XOR/OR/AND
SLLI/SRLI/SRAI/ORI/ANDI/XORI/ADDI
的alu_control控制信号是重合的
但是可以复用
因为R和I的这几条指令而言
都是由opcode rd,rs1(rs),rs2(imm)格式
R型的b是源寄存器rs2 而I型的b是imm立即数
以及算数右移是>>>
强制转为有符号是$signed(xxx)

second:新增支持所有b型指令
跳转的标签地址由汇编器进行计算得出 自动把标签的地址加入到imm里面 之后舍弃掉标签
舍弃到之前的zero线连接到AND门
转而增加电路单元branch_unit来直接连接rdata1和rdata2以及funct3去判断b型指令然后直接传入and门 而其他指令本身就不会激活and门的另一端 所以没有影响