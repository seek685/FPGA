vlog pc.sv imem.sv if_id.sv id_ex.sv ex_mem.sv regfile.sv alu.sv immgen.sv control.sv branch_unit.sv myCPU.sv
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
字节选址,一个地址只能存储1个字节 而32位的数据需占4个字节的空间,也就是四个地址,低两位的地址则恰恰代表了4个寻址空间的索引
assign selected_byte=word>>{addr[1:0],3'b000};
5位每次都加8个字节 高位增加的addr 而后续的低位3刚刚好可以表达8 恰好可以表达4个字节中四选一
忘记了时序逻辑可以不用写default
因为时序逻辑本身就可以保存

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
-------------------------------------------------------
五级流水线:

把dram改为bram:
    旧：采用distributed ram 然后写是同步 读是异步 但是占用太多lut资源。
    新：
    在driver层：
    1，vivado开启了字节写使能 如果不开启字节写使能的话 那么你要写半字必须先读后写 因为为了不改变其他位置上的值（vivado设置了32bit的位宽 寻址到以及写的地址都是4字节） 如果开启了写字节使能 bram内部自动帮你保持其他位置上的值 可以直接写 也符合常识 也不会因为时序混乱出问题。
    2，dram_driver读的时候要考虑到读的偏移和掩码 必须是之前的那个 而写不需要是是因为 读的时候是第一时钟沿把地址送出去了 而第二个时钟沿才得到读出来的地址 所以第二个时钟沿可能把后续的地址也输入进去了 然后这时候进行读的操作 得到的数据就是新地址读出来的数据 原来的被丢失了（这个读的说法其实是错误的 ） 而写操作不一样 直接把地址输入后上升沿直接写 哪怕时候再来一个写的地址 但是因为写操作已经完成了 没有任何影响
    3，正确的来说应该是读的数据输出在那个时钟周期末期已经输出了 关键是指你输出的数据当要做读的选择 比如读字 半字等等的时候你的选择信号必须是你当时那个指令的 而不是后续的 而在driver层做锁存判断就是为了避免在输出数据的时候在driver读由于新的指令信号到来 导致这时候的选择读信号可能是新的 而不是原来旧的信号 那么读到的就大概不是你想要的 这应该才是对的 总的来说就是 无论是哪一层使用bram返回的数据 并做处理时使用的必须是与该数据同一笔请求的offset和mask。
    在perip_bridge层:
    1,在这里通过perip_addr以及写使能来区分并且生成读使能传输给diver和bram，bram_sel=(perip_addr>=BRAM_ADDR_START&&perip_addr< BRAM_ADDR_END)  assign bram_ren=(bram_sel&&!perip_wen)   assign bram_wen=(bram_sel&&perip_wen)
    不必所有的端口都加入一路读的并且全程传输下来
    2,在这里我参照了在driver写的时候的思路 为了防止读的时候读是新的 并且覆盖了旧数据 我把两个信号在时钟周期锁存 perip_addr以及perip_wen锁存进perip_addr_q和perip_wen_q ai认可了我想法 但是还没有验证不确定到时会不会有问题

优化:
    原先的:
    1，bram_din={16'b0, perip_wdata[15:0]}<<(offset * 8);
    bram_we=4'b0011 << offset;
    变成->bram_din = {2perip_wdata[15:0]};
    bram的写入逻辑最终还是由地址决定 既然要写的部分已经确定了 那我直接整个字节都复制成一样的 然后不需要再进行移位的操作 原先移位的操作综合后是得到一组多路选择器
    现在是写数据直连bram 不再需要控制信号控制 直接把最长路径砍了
    2，perip_addr >= 32'h8010_0000 &&perip_addr <  32'h8014_0000
    原先的是判断bram的地址 需要完成两次比较 而改为perip_addr[31:18]==14'h2004之后 相当于把两个32位的比较器变成了一个14位相等的比较器 
    32'h8010_0000-32'h8014_0000=0x40000 0x40000是18位对齐 而本身0x8010_0000本身就是18位 所以在这个区间的值全都是
    3，对于BRAM诸如此类的敏感时序逻辑以及依赖时钟采样的模块 通常优先考虑同步复位 包括BRAM地址 以及PC 流水级寄存器 可以变更为默认同步复位 而明确异步需求的时候才使用异步 让RTL 更符合 FPGA 硬件资源和同步时序分析模型，从而让综合、实现（布局布线）和 STA 能够更容易、更加准确地把你的设计映射成可靠的硬件。
    4，对于跳转冲刷 原先是在id阶段得知是跳转指令或者分支指令 而在ex阶段的话如果要跳转执行冲刷 然后白白浪费两个时钟周期 
    做出的改进方法是 在id阶段判断并且得到跳转地址 然后只需要浪费一个时钟周期即可 
    jalr指令作为灵活跳转指令以及可以作为ret的指令 他的跳转目标可以是寄存器 应该灵活的变量需要计算得到 而jal指令跳转的是相对地址在编译期基于可以知道 因此只有把jal指令提前到id阶段刚刚好可以把惩罚减少到一个周期 而jalr是需要alu计算的 所以只对jal提前
    

    


    
