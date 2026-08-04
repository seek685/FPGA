# Day5 ALU 笔记

## 模块规格

- 输入：`a[31:0]`、`b[31:0]`、`alu_control[3:0]`；输出：`result[31:0]`、`zero`
- 纯组合逻辑（无时钟），`always @(*)` + `case` 分派 + `assign zero`
- 编码表：`0=ADD 1=SUB 2=AND 3=OR`，default → 0

## 核心原理

- ALU 本质是 **并行运算 + MUX**：所有运算同时算，alu_control 选一路输出
- 减法 = `a + (~b) + 1`（补码取负），复用加法器，硬件无"减法器"
- 不做溢出检测：RV32I 基础指令不产生溢出异常
- 两级译码（主控 ALUOp + funct3/funct7 → ALU_decoder → alu_control）在 ALU **模块外**，今天不写；编码表就是两边的契约

## 踩坑记录

- `module` 后忘写模块名 → 语法错误
- Verilog `case` **无 fall-through，没有 `break`**（C 思维残留）
- `always` 块内赋值的必须是 `reg`；输入端口不能是 `reg`
- case 不写 `default` → 推导 latch
- **`#10` 必须放在赋值之后、检查之前**：同时刻读会读到旧值（进程调度顺序）
- `$finish` 等系统任务只能写在 initial/always 过程块内

## tb 要点

- 无时钟：赋值 → `#10` → 检查，逐组顺序执行
- 期望值独立手算，用 `!==` 比对，错误计数，ALL PASS 收尾
- 关键用例：ADD 回绕（FFFF_FFFF+1=0，zero=1）、SUB 得负（3-5=FFFF_FFFE）、zero 正反面、default 表外编码

## 验证

ModelSim 仿真 ALL PASS，波形抽查正常（2026-08-04）
