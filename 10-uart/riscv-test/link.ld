OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*
 * Rigorous, non-overlapping memory map:
 *   imem : 0x80000000 .. 0x80001FFF   (instructions, read by PC)
 *   dmem : 0x00000000 .. 0x00001FFF   (data,        read/write by load/store)
 *
 * The two memories are separate Harvard ports, so the same 32-bit address
 * never reaches both - there is no bus contention. Each range is unique.
 * tohost is pinned at 0x00001000 so the testbench can watch a fixed index.
 */
SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x40);
  .text : { *(.text) }

  . = 0x00000000;
  .data : { *(.data) }
  .bss : { *(.bss) }

  . = 0x00001000;
  .tohost : { *(.tohost) }
  _end = .;
}
