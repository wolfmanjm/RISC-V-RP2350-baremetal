OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx)  : ORIGIN = 0x10000000, LENGTH = 4M
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 512K
}

SECTIONS {
    .text : {
        *(.text*)
    } > FLASH

    .data : {
        *(.data*)
    } > RAM

    .bss : {
        *(.bss*)
    } > RAM

    .stack (NOLOAD) : {
        . = ALIGN(8);
        _stack_top = . + 4K; /* 4KB stack */
    } > RAM
}
