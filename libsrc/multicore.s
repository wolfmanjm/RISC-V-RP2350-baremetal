.section .text

.macro pushra
  	addi sp, sp, -4
  	sw ra, 0(sp)
.endm

.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, 4
.endm


.include "interrupt_vectors.s"

.section .data

core1_sp:
	.dcb.b 1024
core1_sp_end:
	.word 0
cmd_sequence:
	.word 0
	.word 0
	.word 1
	.word __VECTOR_TABLE
	.word core1_sp_end
core1_entry:
	.word 0 # entry
cmd_sequence_end:
	.word 0

.equ SIO_BASE, 0xd0000000
.equ _SIO_FIFO_ST, 0x050
.equ _SIO_FIFO_WR, 0x054
.equ _SIO_FIFO_RD, 0x058

.equ SIO_FIFO_ST_VLD_BITS, 0x00000001
.equ SIO_FIFO_ST_RDY_BITS, 0x00000002

.equ PSM_BASE, 0x40018000
  .equ _FRCE_ON, 0x00000000
    .equ b_FRCE_ON_PROC1, 1<<24
  .equ _FRCE_OFF, 0x00000004
    .equ b_FRCE_OFF_PROC1, 1<<24
    .equ o_FRCE_OFF_PROC1, 24
 .equ _DONE, 0x0000000c
    .equ b_DONE_PROC1, 1<<24

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

.section .text
.globl launch_core1
# a0 is address of function to run in core1
# a1 is stack pointer for core1 (unless 0 in which case it is the builtin 1024bytes one above)
launch_core1:
	pushra
	la t0, core1_entry
	sw a0, 0(t0)
	beqz a1, 1f
	sw a1, -4(t0)

	# disable FIFO IRQ
1:	li a0, SIO_IRQ_FIFO
	li a1, 0
	call enable_irq

	li t3, SIO_BASE
	# send sequence to core1
ta:	la t0, cmd_sequence
1:	lw t2, 0(t0)
	bnez t2, 3f

	# drain fifo
2:	lw t4, _SIO_FIFO_ST(t3)
	andi t4, t4, SIO_FIFO_ST_VLD_BITS
	beqz t4, 3f
	lw t4, _SIO_FIFO_RD(t3)
	slt x0, x0, x1  	# SEV h3.unblock
	j 2b

	# wait for room in FIFO
3:	lw t4, _SIO_FIFO_ST(t3)
	andi t4, t4, SIO_FIFO_ST_RDY_BITS
	beqz t4, 3b

	# write cmd to core1 fifo
	sw t2, _SIO_FIFO_WR(t3)
	slt x0, x0, x1  	# SEV h3.unblock

	# wait for response
4:	lw t4, _SIO_FIFO_ST(t3)
	andi t4, t4, SIO_FIFO_ST_VLD_BITS
	bnez t4, 5f
	slt x0, x0, x0  	# WFE h3.block
	j 4b

	# read response and compare with what we sent
5:	lw t4, _SIO_FIFO_RD(t3)
	bne t4, t2, ta   			# move to next state on correct response (echo-d value) otherwise start over
	addi t0, t0, 4 				# seq+=4
	la t4, cmd_sequence_end
	bne t0, t4, 1b

	popra
	ret

.globl stop_core1
stop_core1:
	pushra

	li t0, PSM_BASE|WRITE_SET
	li t1, b_FRCE_OFF_PROC1
	sw t1, _FRCE_OFF(t0)
	li t0, PSM_BASE
1:	lw t1, _FRCE_OFF(t0)
	bexti t1, t1, o_FRCE_OFF_PROC1
	beqz t1, 1b
	# disable FIFO IRQ
	li a0, SIO_IRQ_FIFO
	li a1, 0
	call enable_irq
	li t0, PSM_BASE|WRITE_CLR
	li t1, b_FRCE_OFF_PROC1
	sw t1, _FRCE_OFF(t0)
	# wait for response
	li t0, SIO_BASE
2:	lw t1, _SIO_FIFO_ST(t0)
	andi t1, t1, SIO_FIFO_ST_VLD_BITS
	bnez t1, 3f
	slt x0, x0, x0  	# WFE h3.block
	j 2b
	# read response and check it is zero
3:	lw t1, _SIO_FIFO_RD(t0)
	beqz t1, 4f
	# should have read zero here
	nop
4: 	popra
	ret

# TODO move this to an app
.include "./appsrc/blink.s"
.globl test_multi_core
test_multi_core:
	pushra
	call uart_init

1:	la a0, blink_test
	li a1, 0 			# use internal stack
	call launch_core1	# run blink test in core1
	# call toggle_pin		# run toggle_pin in core0

	# monitor uart for input and stop or start core1 accordingly
	call uart_getc
	call stop_core1
	call uart_getc
	j 1b

	popra
	ret
