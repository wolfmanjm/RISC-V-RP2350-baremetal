.section .text
.globl blink

.equ SYSCTL_BASE,    0x40000000
.equ CLK_EN_REG,     SYSCTL_BASE + 0x100   # Clock enable register

.equ PAD_ISO_REG,    0x40038000 + (25 + 1) * 4   # Pad isolation control register for GPIO25

.equ IOMUX_BASE,     0x40028000
.equ IOMUX_GPIO25,   IOMUX_BASE + ((25 * 8) + 4) # IOMUX register for GPIO25

.equ SIO_BASE,       0xD0000000
.equ _GPIO_OUT_REG,  0x10       # GPIO output register
.equ _GPIO_OUT_SET,  0x18       # GPIO output set register
.equ _GPIO_OUT_CLR,  0x20       # GPIO output clear register
.equ _GPIO_OUT_XOR,  0x28       # GPIO output xor
.equ _GPIO_OE_SET, 	 0x38       # GPIO direction register
.equ GPIO25_MASK,    (1 << 25)	# Bitmask for GPIO25


blink:
    # Configure IOMUX for GPIO25
    li t0, IOMUX_GPIO25
    lw t1, 0(t0)
    li t2, ~0x1F
    and t1, t1, t2 	 # clear it first
    ori t1, t1, 5        # Function 5 selects SIO mode
    sw t1, 0(t0)         # Set IOMUX for GPIO15

    # Set GPIO25 as an output
    li t0, SIO_BASE
	li t1, GPIO25_MASK
    sw t1, _GPIO_OE_SET(t0)         # Set GPIO25 as output

    # Clear Pad Isolation for GPIO
    li t0, PAD_ISO_REG
    lw t1, 0(t0)
	li t2, ~0x100
    and t1, t1, t2  # Clear GPIO25 isolation bit
    sw t1, 0(t0)

	li t0, SIO_BASE
	li t2, GPIO25_MASK

1:	sw t2, _GPIO_OUT_SET(t0)        # HIGH GPIO15
	li a0, 700
	call delayms
	sw t2, _GPIO_OUT_CLR(t0)        # LOW GPIO15
	li a0, 300
	call delayms
    j 1b
