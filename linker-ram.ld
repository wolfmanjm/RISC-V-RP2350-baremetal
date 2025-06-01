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
        __logical_binary_start = .;
        KEEP (*(.binary_info_header))
        __binary_info_header_end = .;
        KEEP (*(.embedded_block))
        __embedded_block_end = .;

   		. = ALIGN(4);
   	    *(.time_critical*)

   		_stext = .;
   		*(.text*)
   		_etext = .;
   	} > ram1

	/* used by the startup to initialize data */
	_sidata = LOADADDR(.data);

   .data : {
        . = ALIGN(4);
	    _sdata = .;        /* create a global symbol at data start */
   		*(.data)
   		*(.data*)
   		_edata = .;
   		*(.rodata*)
        . = ALIGN(4);
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

    ASSERT( __binary_info_header_end - __logical_binary_start <= 1024, "Binary info must be in first 1024 bytes of the binary")
    ASSERT( __embedded_block_end - __logical_binary_start <= 4096, "Embedded block must be in first 4096 bytes of the binary")
}
