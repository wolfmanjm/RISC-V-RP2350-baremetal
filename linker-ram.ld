OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
   flash(RX)  : ORIGIN = 0x10000000, LENGTH = 4M
   ram1(RWX)  : ORIGIN = 0x20000000, LENGTH = 256K
   ram2(RWX)  : ORIGIN = 0x20040000, LENGTH = 256K
   ram3(RWX)  : ORIGIN = 0x20080000, LENGTH = 8K
}

SECTIONS
{
   .text : { *(.text*) } > ram1
   .data : { *(.data*)} > ram2
   .rodata : { *(.rodata*)} > ram1
}
