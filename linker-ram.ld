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
   .text : {
   	    *(.time_critical*)

   		. = ALIGN(4);
   		_stext = .;
   		*(.text*)
   		_etext = .;
   	} > ram1

	/* used by the startup to initialize data */
	_sidata = LOADADDR(.data);

   .data : {
	    _sdata = .;        /* create a global symbol at data start */
   		*(.data)
   		*(.data*)
   		_edata = .;
   	} > ram2

   .rodata : { *(.rodata*)} > ram1

   /* uninitialized data */
   .bss : {
	    . = ALIGN(4);
	    _sbss = .;        /* create a global symbol at data start */
        *(.bss)
        *(.bss*)
	    . = ALIGN(4);
	    _ebss = .;        /* define a global symbol at data end */
    } > ram2
}
