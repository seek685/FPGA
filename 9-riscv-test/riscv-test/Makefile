# ============================================================
# riscv-test Makefile  —— 完全自包含，替代 build.cmd + bin2hex.py
#
# 只用工具链自带的东西，没有额外脚本：
#   gcc       .S -> .elf         编译+链接
#   objcopy   .elf -> .bin       抽取纯字节流
#   od        .bin -> hex        内联打包成 32 位小端字（替代 bin2hex）
#   truncate  dmem 补 0 到 tohost 区域
#
# 用法（在 Git Bash 里跑，别用 cmd/PowerShell）:
#   make            编译全部 42 个测试 -> hex/ 目录
#   make hex/add.hex        只编 add 的指令镜像
#   make clean      删掉 build/ 和 hex/
# ============================================================

RISCV_PREFIX ?= riscv-none-elf-
RT_SRC       ?= D:/_small_eyes/riscv-tests-full
ARCH         ?= rv32i_zifencei
ABI          ?= ilp32
# dmem 补到 tohost(索引1024) + fromhost -> 1056 字 = 4224 字节
DMEM_BYTES   ?= 4224

ISA_DIR  := $(RT_SRC)/isa/rv32ui
MACROS   := $(RT_SRC)/isa/macros/scalar

TESTS := $(notdir $(basename $(wildcard $(ISA_DIR)/*.S)))
IMEMS := $(addprefix hex/,$(addsuffix .hex,$(TESTS)))
DMEMS := $(addprefix hex/data_,$(addsuffix .hex,$(TESTS)))

.PHONY: all clean
all: $(IMEMS) $(DMEMS)

# ---- 模式规则 1: .S -> .elf（编译+链接）----
build/%.elf: $(ISA_DIR)/%.S riscv_test.h link.ld
	@mkdir -p build
	$(RISCV_PREFIX)gcc -march=$(ARCH) -mabi=$(ABI) -static -mcmodel=medany \
		-nostdlib -nostartfiles -I. -I$(MACROS) -Tlink.ld $< -o $@

# ---- 模式规则 2: .elf -> 指令镜像 hex（od 内联打包）----
hex/%.hex: build/%.elf
	@mkdir -p hex
	$(RISCV_PREFIX)objcopy -O binary --only-section=.text.init --only-section=.text $< $*.bin
	od -An -v --endian=little -tx4 $*.bin > $@
	rm -f $*.bin

# ---- 模式规则 3: .elf -> 数据镜像 hex（补 0 到 tohost）----
hex/data_%.hex: build/%.elf
	@mkdir -p hex
	$(RISCV_PREFIX)objcopy -O binary --only-section=.data $< $*.datbin || true
	touch $*.datbin
	truncate -s $(DMEM_BYTES) $*.datbin
	od -An -v --endian=little -tx4 $*.datbin > $@
	rm -f $*.datbin

.PRECIOUS: build/%.elf

clean:
	rm -rf build hex
