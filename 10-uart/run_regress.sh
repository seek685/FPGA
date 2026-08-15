#!/usr/bin/env bash
# ============================================================
# run_regress.sh — rv32ui 全量回归
#
# 用法（Git Bash，工程根目录）:
#   ./run_regress.sh
#
# 前提:
#   1. riscv-test/hex/ 已生成（cd riscv-test && make）
#   2. RTL 已编译（vlog pc.v imem.v dmem.v regfile.v ALU.v immgen.v \
#                         control.v branch_unit.v cpu_top.v tb_riscv32i.v）
#
# 原理: 逐个测试把 hex 复制成 program.hex / dmem_data.hex，
#       用 tb_riscv32i 跑 vsim，抓取 PASS / Fail / TIMEOUT，
#       结果写入 regress.log
# ============================================================
cd "$(dirname "$0")"

pass=0; total=0
: > regress.log
for h in riscv-test/hex/*.hex; do
  t=$(basename "$h" .hex)
  case $t in data_*) continue;; esac          # 跳过数据镜像
  cp "$h" program.hex
  cp "riscv-test/hex/data_$t.hex" dmem_data.hex
  out=$(timeout 90 vsim -c -do "run -all" work.tb_riscv32i 2>&1)
  res=$(echo "$out" | grep -oE "[0-9]+ +cycles +(PASS|Fail)|TIMEOUT" | head -1)
  echo "$t: ${res:-NO_RESULT}" | tee -a regress.log
  total=$((total+1))
  case $res in *PASS*) pass=$((pass+1));; esac
done
echo "=== PASS $pass / $total ===" | tee -a regress.log
