# setup generic GPIO pins as input or output etc
.section .text

.equ SYSCTL_BASE,    0x40000000
.equ CLK_EN_REG,     SYSCTL_BASE + 0x100   # Clock enable register

.equ PADS_BANK0_BASE, 0x40038000   # Pad isolation control register (pin# * 4) + 4

.equ IO_BANK0_BASE, 0x40028000   # pin# * 8
.equ _GPIO_STATUS, 0x000
.equ _GPIO_CTRL, 0x004

.equ SIO_BASE,       0xD0000000
.equ _GPIO_IN,  	 0x04       # GPIO input register
.equ _GPIO_OUT_REG,  0x10       # GPIO output register
.equ _GPIO_OUT_SET,  0x18       # GPIO output set register
.equ _GPIO_OUT_CLR,  0x20       # GPIO output clear register
.equ _GPIO_OUT_XOR,  0x28       # GPIO output xor

.equ _GPIO_OE_SET, 0x38         # GPIO set direction register
.equ _GPIO_OE_CLR, 0x40         # GPIO clear direction register

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# set pin specified in a0 as output
.globl pin_output
pin_output:
    # Configure FUNC
    li t0, IO_BANK0_BASE
    sh3add t0, a0, t0
    li t1, 5        		# Function 5 selects SIO mode
    sw t1, _GPIO_CTRL(t0)   # Set IOMUX

    # Set as an output
    li t0, SIO_BASE
    bset t1, zero, a0
    sw t1, _GPIO_OE_SET(t0)         # Set GPIO as output

    # Clear Pad Isolation for GPIO
    li t0, PADS_BANK0_BASE
    sh2add t0, a0, t0
    li t1, 0x0030	# drive stength 12MA, clear ISO bit
    sw t1, 4(t0)
    ret

# set pin specified in a0 as input with pu
.globl pin_input_pu
pin_input_pu:
    # Configure FUNC
    li t0, IO_BANK0_BASE
    sh3add t0, a0, t0
    li t1, 5        		# Function 5 selects SIO mode
    sw t1, _GPIO_CTRL(t0)   # Set IOMUX

    # Set as an inout
    li t0, SIO_BASE
    bset t1, zero, a0
    sw t1, _GPIO_OE_CLR(t0)   # Set GPIO as input

    # Clear Pad Isolation for GPIO
    li t0, PADS_BANK0_BASE
    sh2add t0, a0, t0
    li t1, 0x0048	# input enable, pullup, clear ISO bit
    sw t1, 4(t0)
    ret

# these take the pin# in a0
.globl pin_high
pin_high:
	bset t1, zero, a0
    li t0, SIO_BASE
	sw t1, _GPIO_OUT_SET(t0) # set HIGH
	ret

.globl pin_low
pin_low:
	bset t1, zero, a0
    li t0, SIO_BASE
	sw t1, _GPIO_OUT_CLR(t0) # set HIGH
	ret

.globl pin_toggle
pin_toggle:
	bset t1, zero, a0
    li t0, SIO_BASE
	sw t1, _GPIO_OUT_XOR(t0) # set HIGH
	ret

.globl pin_get
pin_get:
    li t0, SIO_BASE
	lw t0, _GPIO_IN(t0)
	bext a0, t0, a0
	ret

.globl test_gpio
test_gpio:
	li a0, 25
	call pin_output
	li a0, 15
	call pin_input_pu

	# if pin15 is high then set pin25 high etc
1:	li a0, 15
	call delayms
	li a0, 15
	call pin_get
	beqz a0, 2f
	li a0, 25
	call pin_high
	j 1b

2:	li a0, 25
	call pin_low
	j 1b

.globl test_breakout
test_breakout:
	# set pins to outputs
	la s0, led_pins
1:	lw a0, 0(s0)
	beqz a0, 2f
	call pin_output
	addi s0, s0, 4
	j 1b

	# toggle each pin on or off
2:	la s0, led_pins
1:	lw a0, 0(s0)
	beqz a0, 3f
	call pin_toggle
	addi s0, s0, 4
	li a0, 100
	call delayms
	j 1b

3: 	j 2b

.section .data
led_pins:
	.word 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 26, 27, 28, 0
