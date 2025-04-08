MEMORY
{
   rom(RX)   : ORIGIN = 0x20000000, LENGTH = 0x01000
   ram(RX)   : ORIGIN = 0x20008000, LENGTH = 0x10000
}

SECTIONS
{
   .text : { *(.text*) } > rom
   .data : { *(.data*)} > ram
}
