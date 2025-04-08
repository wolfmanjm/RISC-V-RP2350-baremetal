.section .text
.globl toggle_pin

.equ SYSCTL_BASE,    0x40000000
.equ CLK_EN_REG,     SYSCTL_BASE + 0x100   # Clock enable register

.equ PAD_ISO_REG,    0x40038000 + 0x40   # Pad isolation control register for GPIO15

.equ IOMUX_BASE,     0x40028000
.equ IOMUX_GPIO15,   IOMUX_BASE + 0x7C     # IOMUX register for GPIO15

.equ SIO_BASE,       0xD0000000
.equ _GPIO_OUT_REG,  0x10       # GPIO output register
.equ _GPIO_OUT_SET,  0x18       # GPIO output set register
.equ _GPIO_OUT_CLR,  0x20       # GPIO output clear register
.equ _GPIO_OUT_XOR,  0x28       # GPIO output xor
.equ _GPIO_OE,   	 0x30       # GPIO direction register

.equ GPIO15_MASK,    (1 << 15)             # Bitmask for GPIO15


toggle_pin:
    # Configure IOMUX for GPIO15
    li t0, IOMUX_GPIO15
    lw t1, 0(t0)
    li t2, ~0x1F
    and t1, t1, t2 	 # clear it first
    ori t1, t1, 5        # Function 5 selects SIO mode
    sw t1, 0(t0)         # Set IOMUX for GPIO15

    # Set GPIO15 as an output
    li t0, SIO_BASE
    lw t1, _GPIO_OE(t0)  # Read current GPIO OE
	li t2, GPIO15_MASK
	or t1, t1, t2
    sw t1, _GPIO_OE(t0)         # Set GPIO15 as output

    # Clear Pad Isolation for GPIO
    li t0, PAD_ISO_REG
    lw t1, 0(t0)
	li t2, ~0x100
    and t1, t1, t2  # Clear GPIO15 isolation bit
    sw t1, 0(t0)

	li t0, SIO_BASE
	li t2, GPIO15_MASK

# inner loop is 3 cycles as branch is predicted so total is 3000 cycles
# with 12MHz clock total is 250.33us or 83.4ns/cycle
# with sys clk set to 150mHz we get 20us or 6.6ns/cycle
loop:
	csrr t3, mcycle
	sw t2, _GPIO_OUT_SET(t0)        # HIGH GPIO15
	li t1, 1000
1:	addi t1, t1, -1
	nop
	bnez t1, 1b
	sw t2, _GPIO_OUT_CLR(t0)        # LOW GPIO15
	csrr t4, mcycle
	sub	t3, t4, t3		# count cycles of inner loop

	# delay before going high again so logic analyzer won't miss it (83ns is smaller than the sample window)
	li t1, 10
1:	addi t1, t1, -1
	bnez t1, 1b

    j loop
