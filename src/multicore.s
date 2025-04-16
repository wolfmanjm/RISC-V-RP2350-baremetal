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

.section .text
.globl launch_core1
# a0 is address of function to run in core1
launch_core1:
	pushra
	la t0, core1_entry
	sw a0, 0(t0)

	# disable FIFO IRQ
	li a0, SIO_IRQ_FIFO
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

3:	lw t4, _SIO_FIFO_ST(t3)
	andi t4, t4, SIO_FIFO_ST_RDY_BITS
	beqz t4, 3b

	# write cmd to core1 fifo
	sw t2, _SIO_FIFO_WR(t3)
	slt x0, x0, x1  	# SEV h3.unblock

4:	lw t4, _SIO_FIFO_ST(t3)
	andi t4, t4, SIO_FIFO_ST_VLD_BITS
	bnez t4, 5f
	slt x0, x0, x0  	# WFE h3.block
	j 4b

5:	lw t4, _SIO_FIFO_RD(t3)
	bne t4, t2, ta   			# move to next state on correct response (echo-d value) otherwise start over
	addi t0, t0, 4 				# seq+=4
	la t4, cmd_sequence_end
	bne t0, t4, 1b

	popra
	ret

.globl test_multi_core
test_multi_core:
	la a0, blink_test
	call launch_core1	# run blink test in core1
	call toggle_pin		# run toggle_pin in core0

1:	j 1b

	ret
