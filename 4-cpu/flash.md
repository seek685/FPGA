vlog pc.v imem.v dmem.v regfile.v ALU.v immgen.v control.v cpu_top.v
vsim -c -do "quit" work.cpu_top
第一条是编译的命令
第二条是查看端口对接 有没有错误 有没有连线好
imem.v 里 的`$readmemh("program.hex", imem)` 在仿真 0 时刻把文件加载进指令存储器，相当于烧进 ROM 的固件。文件空 = imem 全 X = CPU 空转。当前还不支持lui等立即数加载的指令 需要往dmem里面填入几个数据用lw加载出来
对于imem 地址pc减去基地址之后 imem从0索引开始
而后续读dmem的读地址这时候已经是准确地址 直接右移2即可对应上索引
