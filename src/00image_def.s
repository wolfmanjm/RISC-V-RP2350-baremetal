.equ STACK_TOP, 0x20080000 - 0x0100

.section .embedded_block
# -----------------------------------------------------------------------------
.p2align 4 # This special signature must appear within the first 4 kb of
image_def: # the memory image to be recognised as a valid RISC-V binary.
# -----------------------------------------------------------------------------

.word 0xffffded3
.word 0x11010142
.word 0x00000344
.word _start
.word STACK_TOP
.word 0x000004ff
.word 0x00000000
.word 0xab123579
