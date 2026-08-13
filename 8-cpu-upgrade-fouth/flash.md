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

third:
增加了jal和jalr以及aupic和lui指令支持
以及把原先的MemtoReg和PC_src mux都拓展成了2bit位宽
PC_src mux新增了一个控制信号jump去选择跳转的区分以及是否跳转 而且pc_src的选择信号的控制输入只是由branch和branch_1来选择是否是分支 无法区分是不是要跳转 
MemtoReg改成了三路输入 因为lui和aupic需要把结果输入rd 也就是通过alu_result进入选择之后来到wdata也就是写入rd 
$fatal 输出错误信息 并且可以写入0 1 2来选择控制仿真结束的行为

$fouth
增加对存储指令和加载指令的补充：SB SH，LB/LH LBU/LHU
字节选址,一个地址只能存储1个字节 而32位的数据需占4个字节的空间,也就是四个地址,低两位的地址则恰恰是代表了4个寻址空间的索引
assign selected_byte=word>>{addr[1:0],3'b000};
5位每次都加8个字节 高位增加的addr 而后续的低位3刚刚好可以代表8 恰好可以表达4个字节中四选一
忘记了时序逻辑可以不用写default
因为时序逻辑本身就可以保存