OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx)  : ORIGIN = 0x10000000, LENGTH = 4M
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 512K
    RAM2  (RWX) : ORIGIN = 0x20080000, LENGTH = 8K
}

SECTIONS {
    .text : {
        __logical_binary_start = .;
        KEEP (*(.binary_info_header))
        __binary_info_header_end = .;
        KEEP (*(.embedded_block))
        __embedded_block_end = .;

   		. = ALIGN(4);
   		_stext = .;
   		*(.text*)
   		_etext = .;
   		. = ALIGN(4);
    } > FLASH

	/* used by the startup to initialize data */
	_sidata = LOADADDR(.data);

	/* Initialized data sections goes into RAM */
    .data : {
        . = ALIGN(4);
	    _sdata = .;        /* create a global symbol at data start */
	    *(.time_critical*)

	    *(.data)           /* .data sections */
	    *(.data*)          /* .data* sections */

	    _edata = .;        /* define a global symbol at data end */
        . = ALIGN(4);
    } > RAM AT> FLASH

    .bss : {
	    . = ALIGN(4);
	    _sbss = .;        /* create a global symbol at data start */
        *(.bss)
        *(.bss*)

	    . = ALIGN(4);
	    _ebss = .;        /* define a global symbol at data end */
    } > RAM

    .rodata : {
    	*(.rodata*)
    } > FLASH

    ASSERT( __binary_info_header_end - __logical_binary_start <= 1024, "Binary info must be in first 1024 bytes of the binary")
    ASSERT( __embedded_block_end - __logical_binary_start <= 4096, "Embedded block must be in first 4096 bytes of the binary")
}
