把control和alu_decoder集成在一起 放在同一个.v文件里面 
alu_decoder和control这里才用到alu_op[1:0]这根wire
在这里例化减少顶层的连线例化
以及task的用法
task xxx;
    input ...
    input ...
    input ...
    begin 
            对于真值表的判断 可以拼接在一起全部一起判断
            也可以用case的嵌套来判断
            还有verilog里的字符串是按照ASCII去展示的实际上一个字符的%s对应着一个真实存储了一个字节的字符 也就是8bit
            8*16-1代表刚刚好最多展示16个字符串
    end
endtask

xxx(对应task里面的input 注入输入，，，，，);

