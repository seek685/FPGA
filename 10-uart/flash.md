vlog pc.v imem.v dmem.v regfile.v ALU.v immgen.v control.v branch_unit.v cpu_top.v
vsim -c -do "quit" work.cpu_top
第一条是编译的命令
第二条是查看端口对接 有没有错误 有没有连线好
imem.v 里 的`$readmemh("program.hex", imem)` 在仿真 0 时刻把文件加载进指令存储器，相当于烧进 ROM 的固件。文件空 = imem 全 X = CPU 空转。当前还不支持lui等立即数加载的指令 需要往dmem里面填入几个数据用lw加载出来
对于imem 地址pc减去基地址之后 imem从0索引开始
而后续读dmem的读地址这时候已经是准确地址 直接右移2即可对应上索引
----------------------------------------------------
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
--------------------------------------------------------
second:新增支持所有b型指令
跳转的标签地址由汇编器进行计算得出 自动把标签的地址加入到imm里面 之后舍弃掉标签
舍弃到之前的zero线连接到AND门
转而增加电路单元branch_unit来直接连接rdata1和rdata2以及funct3去判断b型指令然后直接传入and门 而其他指令本身就不会激活and门的另一端 所以没有影响
----------------------------------------------------------
third:
增加了jal和jalr以及aupic和lui指令支持
以及把原先的MemtoReg和PC_src mux都拓展成了2bit位宽
PC_src mux新增了一个控制信号jump去选择跳转的区分以及是否跳转 而且pc_src的选择信号的控制输入只是由branch和branch_1来选择是否是分支 无法区分是不是要跳转 
MemtoReg改成了三路输入 因为lui和aupic需要把结果输入rd 也就是通过alu_result进入选择之后来到wdata也就是写入rd 
$fatal 输出错误信息 并且可以写入0 1 2来选择控制仿真结束的行为
-----------------------------------------------------
$fouth
增加对存储指令和加载指令的补充：SB SH，LB/LH LBU/LHU
字节选址,一个地址只能存储1个字节 而32位的数据需占4个字节的空间,也就是四个地址,低两位的地址则恰恰代表了4个寻址空间的索引
assign selected_byte=word>>{addr[1:0],3'b000};
5位每次都加8个字节 高位增加的addr 而后续的低位3刚刚好可以表达8 恰好可以表达4个字节中四选一
忘记了时序逻辑可以不用写default
因为时序逻辑本身就可以保存
----------------------------------------------------
fifth: riscv-tests 官方验证（结果 40/42 PASS）
流程：编译官方 .S 测试 → 转成 hex → $readmemh 喂 imem/dmem → tb 盯 tohost 判 PASS/FAIL
工具链是 xpack riscv-none-elf-gcc，用前 export PATH 指向它的 bin
clone 必须加 --recursive（env 是子模块，GitHub 下的 zip 里 env 是空的，缺 riscv_test.h 和 link.ld）
官方 env/p 跑不了：初始化里全是 csrw/mret/ecall（要特权架构，Zicsr 扩展，-march=rv32i 汇编器直接报错）
做法=官方测试源原封不动 + 自改精简 harness（riscv_test.h 删掉所有 csr/mret/ecall，pass/fail 改成直接写 tohost；link.ld 改地址）
内存映射：imem@0x80000000（pc 减基址再>>2）、dmem@0x0、tohost@0x1000（dmem 下标 1024，dmem 扩到 4096 字）
判定约定（官方规矩）：pass 写 1；fail 写 (用例编号<<1)|1，编号=值>>1，靠 gp 寄存器记录当前用例
makefile 一条龙：gcc -march=rv32i_zifencei（带 zifencei 否则 fence.i 编不过）→ objcopy -O binary --only-section 分 imem/dmem 两次导 → od --endian=little -tx4 拼字 → truncate 补零到 tohost 之后
字节序：RISC-V 小端，bin 里低字节在前，拼字要 b0|b1<<8|b2<<16|b3<<24，反了 CPU 取到的是垃圾
周期数比指令数多是正常的：bypass 测试宏内部有 bne 回跳循环会重复执行
run_regress.sh 一键回归，改 RTL 后必须先 vlog 再跑，否则测的是旧电路
40/42：fence_i 超时=哈佛结构跑不了自修改代码（sw 只写 dmem，imem 不变）；ma_data 挂=要 CSR 异常处理非对齐访存，高阶任务再补
------------------------------------------------------
uart_tx,tb_uart_tx:
module #(
    传入参数
)(

)
时钟频率/波特率等于数据持续时间 也叫波特率分频
clk/baud-1=baud_div因为从0开始记 所以-1
串口发送线空闲时为高电平1 起始发生主动拉低 最终校验再拉高
比如发送一个数据8'hA5 = 1010_0101：
start D0 D1 D2 D3 D4 D5 D6 D7 stop
  0    1  0  1  0  0  1  0  1   1

移位寄存器:装载发送帧
tx_shift <= {1'b1, tx_data, 1'b0};

tx_shift <= {1'b1, tx_shift[9:1]};
txd      <= tx_shift[1];这里读第1位是因为 他们同时赋值 但是移位寄存器还没刷新

UART接收应该在每一位中心采样
所以需要计时器采样baud_cnt
与此同时buad_cnt的reg宽度可以用$clog2()计算
$clog2()用于计算里面的数据的最少需要的位数
比如$clog(9)最少需要4位
检测到起始位
    ↓ 等待 1.5 个位周期
采样 D0
    ↓ 每隔 1 个位周期
采样 D1 ~ D7
D7 中心采样完成后：
再等 1 个位周期到停止位中心并检查 txd == 1
再等 0.5 个位周期，确保停止位完整结束
然后才能发送下一帧 否则 tx_vaild 可能在 DUT 忙碌时被忽略。

end:上升沿锁存整帧并输出起始位；rec() 随后等待到 D0 中心。在 testbench 逐位采样 txd 的同时，DUT 也在并行地按照每个 UART 位周期更新 txd。采完 D7 后再等待一个位周期检查停止位中心，最后再等待半个位周期确保停止位完整结束。