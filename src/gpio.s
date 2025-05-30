# setup generic GPIO pins as input or output etc

# NOTE all calls that take a0 as the pin number should return where possible
# the same pin in a0

.section .text

.macro pushra
  	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)
.endm
.macro popra
  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
.endm

.equ SYSCTL_BASE,    0x40000000
.equ CLK_EN_REG,     SYSCTL_BASE + 0x100   # Clock enable register

.equ PADS_BANK0_BASE, 0x40038000   # Pad isolation control register (pin# * 4) + 4
  .equ _GPIO, 0x00000004
    .equ b_GPIO_SLEWFAST, 1<<0
    .equ b_GPIO_SCHMITT, 1<<1
    .equ b_GPIO_PDE, 1<<2
    .equ b_GPIO_PUE, 1<<3
    .equ m_GPIO_DRIVE, 0x00000030
    .equ o_GPIO_DRIVE, 4
    .equ b_GPIO_IE, 1<<6
    .equ b_GPIO_OD, 1<<7
    .equ b_GPIO_ISO, 1<<8

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

.equ GPIO_FUNC_SIO, 5

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# generic set function for any GPIO pin
# a0 pin, a1 function
.globl gpio_set_function
gpio_set_function:
	# this is exactly the same as the SDK gpio_set_function()
	li t0, PADS_BANK0_BASE
    sh2add t0, a0, t0
	lw t1, _GPIO(t0)
	xori t1, t1, b_GPIO_IE
	andi t1, t1, b_GPIO_IE|b_GPIO_OD
	li t2, WRITE_XOR
	or t0, t0, t2
	sw t1, _GPIO(t0)		# Set input enable on, output disable off

    # Zero all fields apart from fsel; we want this IO to do what the peripheral tells it.
	li t0, IO_BANK0_BASE
	sh3add t0, a0, t0 		# get the offet for the pin (pin# * 8)
	sw a1, _GPIO_CTRL(t0) 	# set to requested function

    # Clear Pad Isolation
    li t0, PADS_BANK0_BASE|WRITE_CLR
    sh2add t0, a0, t0
    li t1, b_GPIO_ISO
    sw t1, _GPIO(t0)

	ret

# set or clear (a0) the input enabled bit
.globl gpio_set_input_enabled
gpio_set_input_enabled:
	beqz a1, 1f
	li t0, PADS_BANK0_BASE|WRITE_SET
	j 2f
1:	li t0, PADS_BANK0_BASE|WRITE_CLR
2:  sh2add t0, a0, t0
	li t1, b_GPIO_IE
	sw t1, _GPIO(t0)
	ret

# set fast (a1=1) or slow (a1=0) slew for pin (a0)
.globl gpio_set_slew
gpio_set_slew:
    beqz a1, 1f
    li t0, PADS_BANK0_BASE|WRITE_SET
    j 2f
1:	li t0, PADS_BANK0_BASE|WRITE_CLR
2:  sh2add t0, a0, t0
    li t1, b_GPIO_SLEWFAST
    sw t1, _GPIO(t0)
    ret

# set schmitt (a1=0/1) for pin (a0)
.globl gpio_set_schmitt
gpio_set_schmitt:
    beqz a1, 1f
    li t0, PADS_BANK0_BASE|WRITE_SET
    j 2f
1:	li t0, PADS_BANK0_BASE|WRITE_CLR
2:  sh2add t0, a0, t0
    li t1, b_GPIO_SCHMITT
    sw t1, _GPIO(t0)
    ret

# set pullup for pin (a0)
.globl gpio_set_pullup
gpio_set_pullup:
    # clear pulldown
	li t0, PADS_BANK0_BASE|WRITE_CLR
  	sh2add t0, a0, t0
    li t1, b_GPIO_PDE
    sw t1, _GPIO(t0)
    # set pullup
	li t0, PADS_BANK0_BASE|WRITE_SET
  	sh2add t0, a0, t0
    li t1, b_GPIO_PUE
    sw t1, _GPIO(t0)
    ret

# disable pulls for pin (a0)
.globl gpio_disable_pulls
gpio_disable_pulls:
    # clear pullup and pulldown
	li t0, PADS_BANK0_BASE|WRITE_CLR
  	sh2add t0, a0, t0
    li t1, b_GPIO_PDE|b_GPIO_PUE
    sw t1, _GPIO(t0)
    ret

# set drive strength (a1=0-3) for pin (a0)
.globl gpio_set_drive
gpio_set_drive:
	li t0, PADS_BANK0_BASE
	sh2add t0, a0, t0
	lw t1, _GPIO(t0)
	li t2, ~(m_GPIO_DRIVE)
	and t1, t1, t2
	slli t2, a1, o_GPIO_DRIVE
	or t1, t1, t2
	sw t1, _GPIO(t0)
	ret

# set pin specified in a0 as output
.globl pin_output
pin_output:
	pushra
	mv s1, a0

    # gpio_init()
    li t0, SIO_BASE
    bset t1, zero, s1
    sw t1, _GPIO_OE_CLR(t0)         # Set GPIO as input
	sw t1, _GPIO_OUT_CLR(t0) 		# set LOW

    # Configure FUNC
    mv a0, s1
	li a1, GPIO_FUNC_SIO
	call gpio_set_function

    li t0, SIO_BASE
    bset t1, zero, s1
    sw t1, _GPIO_OE_SET(t0)         # Set GPIO as output

    mv a0, s1
    li a1, 3	# drive stength 12MA
    call gpio_set_drive
    popra
    ret

# set pin specified in a0 as input with pu
.globl pin_input_pu
pin_input_pu:
	pushra
	mv s1, a0

    # gpio_init()
    li t0, SIO_BASE
    bset t1, zero, s1
    sw t1, _GPIO_OE_CLR(t0)	  	# Set GPIO as input
	sw t1, _GPIO_OUT_CLR(t0) 	# set LOW
    # Configure FUNC
    mv a0, s1
    li a1, GPIO_FUNC_SIO
    call gpio_set_function

	li t0, SIO_BASE
    bset t1, zero, s1
	sw t1, _GPIO_OE_CLR(t0) 	# set as input again

    # clear pulldown
	li t0, PADS_BANK0_BASE|WRITE_CLR
  	sh2add t0, s1, t0
    li t1, b_GPIO_PDE
    sw t1, _GPIO(t0)
    # set pullup
	li t0, PADS_BANK0_BASE|WRITE_SET
  	sh2add t0, s1, t0
    li t1, b_GPIO_PUE
    sw t1, _GPIO(t0)

    popra
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
	sw t1, _GPIO_OUT_CLR(t0) # set LOW
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

# GPIO Interrupt Handling We have a table of enabled GPIO interrupts so we only
# need to check them rather than the entire GPIO range. There is also a table
# of callbacks for each enabled GPIO. The size of this table is configurable
# to the number of GPIOs that may need to be enabled for interrupt
.section .data
.equ N_GPIO_INTERRUPTS, 10
gpio_interrupt_enabled:
	# each byte contains the GPIO number that is enabled, 0xFF if not enabled
	.dcb.b N_GPIO_INTERRUPTS, 0xFF

.p2align 2
gpio_interrupt_callbacks:
# has the address of the routine to call when the interrupt is triggered, the
# same position in the table as the gpio_interrupt_enabled table
	.dcb.l N_GPIO_INTERRUPTS

.section .text

.include "interrupt_vectors.s"

.equ IO_BANK0_BASE, 0x40028000
  .equ _INTR0, 0x00000230
  .equ _PROC0_INTE0, 0x00000248
  .equ _PROC0_INTS0, 0x00000278
  .equ _PROC1_INTE0, 0x00000290
  .equ _PROC1_INTS0, 0x000002C0


# acks IRQ for pin in a0 for events in a1
gpio_ack_irq:
	li t0, (IO_BANK0_BASE+_INTR0)
	mv t1, a0
	srli t2, t1, 3 			# gpio/8
	sh2add t2, t2, t0		# register offset for this gpio
	andi t1, t1, 0b0111		# gpio mod 8
	slli t1, t1, 2 			# (gpio mod 8) * 4
	sll t1, a1, t1 			# shift event into correct position
	sw t1, 0(t2) 			# set event bits
	ret

# called when any GPIO has an interrupt
# look through the enabled GPIOs and call the callback if found after ack'ing the IRQ
gpio_default_irq_handler:
	addi sp, sp, -32
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw a1, 8(sp)
  	sw t0, 12(sp)
  	sw t1, 16(sp)
  	sw t2, 20(sp)
  	sw t3, 24(sp)
 	sw t4, 28(sp)

  	# find the interrupt that caused this
  	# we only check the enabled interrupts in the table
    csrr t0, mhartid			# which core are we on
    bnez t0, 11f
	li t4, (IO_BANK0_BASE+_PROC0_INTS0)
	j 21f
11:	li t4, (IO_BANK0_BASE+_PROC1_INTS0)
21:	li t1, 0 								# index into the table
	la t0, gpio_interrupt_enabled
1:	lb t3, 0(t0)
	li t2, -1
	beq t2, t3, 2f 		# not enabled
	# check if this is the one
	srli t2, t3, 3 			# gpio/8
	sh2add t2, t2, t4		# register offset for this gpio
	lw t2, 0(t2)
	andi t3, t3, 0b0111		# gpio mod 8
	slli t3, t3, 2 			# (gpio mod 8) * 4
	srl t2, t2, t3 			# shift event into LSB
	andi t2, t2, 0b1111
	bnez t2, 3f				# it is this one
	# next entry
2:	addi t1, t1, 1
	addi t0, t0, 1
	li t2, N_GPIO_INTERRUPTS
	bne t1, t2, 1b

 	# not found, this is a problem as we can't clear the interrupt
 	# load the pending interrupts for debug
 	li t0, IO_BANK0_BASE
 	lw t1, 0x200(t0)
 	lw t2, 0x208(t0)
	ebreak
4:	j 4b

  	# ack it, t1 has the index, t2 has the event
3:	la t0, gpio_interrupt_enabled
	add t0, t0, t1
	lb a0, 0(t0)		# get the gpio number
	mv a1, t2 			# this is the event mask that caused the interrupt
	mv t3, t1			# save the index
	call gpio_ack_irq 	# ack it to clear it
	mv t1, t3
	# call the callback registered for this GPIO IRQ t1 has the index
	# a0 has the gpio, a1 has the event
	la t0, gpio_interrupt_callbacks
	sh2add t0, t1, t0
	lw t0, 0(t0)
	# call the handler for this GPIO irq
	jalr ra, t0

	# restore regs we used here
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
  	lw t0, 12(sp)
  	lw t1, 16(sp)
  	lw t2, 20(sp)
  	lw t3, 24(sp)
  	lw t4, 28(sp)
	addi sp, sp, 32

	ret

# a0 has pin to enable, a1 has callback, a2 has rising/falling edge as bits 0-3
# returns 1 in a0 if ok otherwise 0 (no room in table)
.globl gpio_enable_interrupt
gpio_enable_interrupt:
	# find unused entry
	li t1, 0
	la t0, gpio_interrupt_enabled
	li t3, -1
	li t4, N_GPIO_INTERRUPTS
1:	lb t2, 0(t0)
	beq t2, t3, 2f
	addi t1, t1, 1
	addi t0, t0, 1
	bne t1, t4, 1b
	li a0, 0
	ret
	# found empty slot
2:	sb a0, 0(t0)
	la t0, gpio_interrupt_callbacks
	sh2add t0, t1, t0
	sw a1, 0(t0)

	# enable the interrupt in H/W
	pushra
	mv s1, a0 			# save pin
	# first ack any outstanding IRQ for the given events
	mv a1, a2 			# events
	call gpio_ack_irq
	# enable GPIOs IRQ
    csrr a0, mhartid
    bnez a0, 3f
	li t0, (IO_BANK0_BASE+_PROC0_INTE0)|WRITE_SET
	j 4f
3:	li t0, (IO_BANK0_BASE+_PROC1_INTE0)|WRITE_SET
4:	mv t1, s1
	srli t2, t1, 3 			# gpio/8
	sh2add t2, t2, t0		# register offset for this gpio
	andi t1, t1, 0b0111		# gpio mod 8
	slli t1, t1, 2 			# (gpio mod 8) * 4
	sll t1, a2, t1 			# shift event into correct position
	sw t1, 0(t2) 			# set event bits

	li a0, 1
	popra
	ret

# a0 has the pin to disable
.globl gpio_disable_interrupt
gpio_disable_interrupt:
	# find entry
	li t1, 0
	la t0, gpio_interrupt_enabled
	li t4, N_GPIO_INTERRUPTS
1:	lb t2, 0(t0)
	beq t2, a0, 2f
	addi t1, t1, 1
	addi t0, t0, 1
	bne t1, t4, 1b
	ret
	# found entry
2:	li t2, 0xFF
	sb t2, 0(t0)
	la t0, gpio_interrupt_callbacks
	sh2add t0, t1, t0
	sw zero, 0(t0)
	# disable the GPIOs IRQ in H/W
    csrr a0, mhartid		# which core are we on
    bnez a0, 3f
	li t0, (IO_BANK0_BASE+_PROC0_INTE0)|WRITE_CLR
	j 4f
3:	li t0, (IO_BANK0_BASE+_PROC1_INTE0)|WRITE_CLR
4:	mv t1, a0
	srli t2, t1, 3 			# gpio/8
	sh2add t2, t2, t0		# register offset for this gpio
	andi t1, t1, 0b0111		# gpio mod 8
	slli t1, t1, 2 			# (gpio mod 8) * 4
	li t3, 0b1111			# clear all the bits (Is this correct or should we specify the mask?)
	sll t3, t3, t1 			# shift event into correct position
	sw t3, 0(t2) 			# clear event bits
	ret

.globl gpio_enable_common_irq
gpio_enable_common_irq:
	pushra
	# set the shared IRQ handler for all GPIO IRQs
	li a0, IO_IRQ_BANK0
	la a1, gpio_default_irq_handler
	call set_irq_vector

	li a0, IO_IRQ_BANK0
	li a1, 1
	call enable_irq
	popra
	ret

.globl gpio_disable_common_irq
gpio_disable_common_irq:
	pushra
	li a0, IO_IRQ_BANK0
	li a1, 0
	call enable_irq
	popra
	ret

.section .text

# Test routines
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

test_gpio_int_handler:
  	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw t0, 8(sp)
  	sw t1, 12(sp)

  	# increment count
  	la t1, irq_count
  	lw t0, 0(t1)
  	addi t0, t0, 1
  	sw t0, 0(t1)

    lw ra, 0(sp)
    lw a0, 4(sp)
  	lw t0, 8(sp)
  	lw t1, 12(sp)
	addi sp, sp, 16
	ret


.globl test_gpio_irq
test_gpio_irq:
	li a0, 25
	call pin_output
	li a0, 15
	call pin_input_pu

	# disable the commoninterrupt until all have been setup
	call gpio_disable_common_irq
	li a0, 15
	la a1, test_gpio_int_handler
	li a2, b_INTR_EDGE_HIGH
	call gpio_enable_interrupt
	# check a0 is 1
	bnez a0, 3f
	ebreak

3:	call gpio_enable_common_irq
	# toggles pin 25 depending on count LSB
1:	wfi
	li a0, 25
 	la t1, irq_count
  	lw t0, 0(t1)
 	andi t0, t0, 1
  	beqz t0, 2f
	call pin_high
	j 1b
2:	call pin_low
	j 1b

	ret

.section .data
led_pins:
	.word 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 26, 27, 28, 0

irq_count: .word 0
