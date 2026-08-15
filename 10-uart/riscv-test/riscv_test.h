// Minimal tohost-protocol riscv_test.h for bare-metal RV32I CPUs
// No CSR, no ecall, no mret, no trap handling. Pass/fail via tohost memory.
#ifndef _ENV_PHYSICAL_SINGLE_CORE_H
#define _ENV_PHYSICAL_SINGLE_CORE_H

#define RVTEST_RV64U  .macro init; .endm
#define RVTEST_RV64UF .macro init; .endm
#define RVTEST_RV32U  .macro init; .endm
#define RVTEST_RV32UF .macro init; .endm

#define TESTNUM gp

#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .align  6;                                                      \
        .globl _start;                                                  \
        .globl start;                                                   \
        .globl _end;                                                    \
_start:                                                                 \
start:                                                                  \
        j reset_vector;                                                 \
        .align 2;                                                       \
trap_vector:                                                            \
        j trap_vector;                                                  \
reset_vector:                                                           \
        li TESTNUM, 0;                                                  \
        init;                                                           \
        EXTRA_INIT;                                                     \
        EXTRA_INIT_TIMER

#define RVTEST_CODE_END

#define RVTEST_PASS                                                     \
        fence;                                                          \
        li TESTNUM, 1;                                                  \
        sw TESTNUM, tohost, t5;                                         \
1:      j 1b

#define RVTEST_FAIL                                                     \
        fence;                                                          \
1:      beqz TESTNUM, 1b;                                               \
        sll TESTNUM, TESTNUM, 1;                                        \
        or TESTNUM, TESTNUM, 1;                                         \
        sw TESTNUM, tohost, t5;                                         \
2:      j 2b

#define EXTRA_DATA
#define EXTRA_INIT
#define EXTRA_INIT_TIMER
#define EXTRA_TVEC_USER
#define EXTRA_TVEC_MACHINE
#define FILTER_TRAP
#define FILTER_PAGE_FAULT

#define RVTEST_DATA_BEGIN                                               \
        EXTRA_DATA                                                      \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 6; .global tohost; tohost: .dword 0; .size tohost, 8;    \
        .align 6; .global fromhost; fromhost: .dword 0; .size fromhost, 8;\
        .popsection;                                                    \
        .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END .align 4; .global end_signature; end_signature:

#endif
