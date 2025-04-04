.section .text
.globl toggle_pin

.equ SYSCTL_BASE,    0x40000000
.equ CLK_EN_REG,     SYSCTL_BASE + 0x100   # Clock enable register

.equ PAD_ISO_REG,    0x40038000 + 0x40   # Pad isolation control register for GPIO15

.equ IOMUX_BASE,     0x40028000
.equ IOMUX_GPIO15,   IOMUX_BASE + 0x7C     # IOMUX register for GPIO15

.equ SIO_BASE,       0xD0000000
.equ GPIO_OUT_REG,   SIO_BASE + 0x10       # GPIO output register
.equ GPIO_OUT_SET,   SIO_BASE + 0x18       # GPIO output set register
.equ GPIO_OUT_CLR,   SIO_BASE + 0x20       # GPIO output clear register
.equ GPIO_OUT_XOR,   SIO_BASE + 0x28       # GPIO output xor
.equ GPIO_OE,   	 SIO_BASE + 0x30       # GPIO direction register

.equ GPIO15_MASK,    (1 << 15)             # Bitmask for GPIO15


toggle_pin:
    # Configure IOMUX for GPIO15
    li t0, IOMUX_GPIO15
    lw t1, 0(t0)
    li t2, ~0x1F
    and t1, t1, t2 	 # clear it first
    ori t1, t1, 5        # Function 5 selects GPIO mode
    sw t1, 0(t0)         # Set IOMUX for GPIO15

    # Set GPIO15 as an output
    li t0, GPIO_OE
    lw t1, 0(t0)         # Read current GPIO OE
	li t2, GPIO15_MASK
	or t1, t1, t2
    sw t1, 0(t0)         # Set GPIO15 as output

    # Clear Pad Isolation for GPIO
    li t0, PAD_ISO_REG
    lw t1, 0(t0)
	li t2, ~0x100
    and t1, t1, t2  # Clear GPIO15 isolation bit
    sw t1, 0(t0)

	li t0, GPIO_OUT_XOR
	li t2, GPIO15_MASK

loop:
	sw t2, 0(t0)        # Toggle GPIO15
	sw t2, 0(t0)        # Toggle GPIO15
    j loop
