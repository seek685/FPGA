把control和alu_decoder集成在一起 放在同一个.v文件里面 
alu_decoder和control这里才用到alu_op[1:0]这根wire
在这里例化减少顶层的连线例化

为什么拆两级译码:主控只看opcode,不知道funct;alu_decoder不知道这条指令要不要写寄存器/内存。
所以主控出"类别"(ALUOp),funct的细节收进alu_decoder,中间只走一根alu_op。
扩全RV32I时,改动集中在alu_decoder。

以及task的用法
task xxx;
    input ...
    input ...
    input ...
    begin 
            tb里对多个输出一起判断:拼接{}一次比较(注意拼接顺序=位序,左边第一个信号占最高位)
            RTL里做多级译码:case的嵌套(如alu_decoder两层case)——拼接是tb手段,case嵌套是RTL手段,别混
            verilog里的字符串按ASCII存储,一个字符占8bit
            [8*16-1:0] 最多存16个字符
    end
endtask

xxx(对应task里面的input 注入输入,,,);
tb里接DUT input的信号声明成reg(要驱动它),接output的声明成wire

