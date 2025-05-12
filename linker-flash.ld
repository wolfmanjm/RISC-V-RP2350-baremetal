OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx)  : ORIGIN = 0x10000000, LENGTH = 4M
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 512K
    RAM2  (RWX) : ORIGIN = 0x20080000, LENGTH = 8K
}

SECTIONS {
    /* XIP code section, runs from (slow) QSPI
    .text : {
   		. = ALIGN(4)
   		_stext = .;
   		*(.text*)
   		_etext = .;
    } > FLASH

	/* used by the startup to initialize data */
	_sidata = LOADADDR(.data);

	/* Initialized data sections goes into RAM */
    .data : {
	    . = ALIGN(4);
	    _sdata = .;        /* create a global symbol at data start */
	    *(.data)           /* .data sections */
	    *(.data*)          /* .data* sections */

	    . = ALIGN(4);
	    _edata = .;        /* define a global symbol at data end */
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
}
