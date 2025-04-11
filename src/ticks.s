.equ SIO_BASE, 0xD0000000
.equ _MTIME, 0x1b0
.equ _MTIMEH, 0x1b4

.equ TICKS_BASE, 0x40108000
.equ _TICKS_CTRL, 0x00
.equ _TICKS_CYCLES, 0x04
.equ _TICKS_COUNT, 0x08

.section .text

.globl setup_ticks

setup_ticks:
	# setup ticks
	li t1, TICKS_BASE
	li t2, 12 			# 12 ticks to get 1uS
	li t3, 1
	li t0, 6
1:	sw zero, _TICKS_CTRL(t1)
	sw t2, _TICKS_CYCLES(t1)
	sw t3, _TICKS_CTRL(t1)
	addi t0, t0, -1
	beqz t0, 2f
	addi t1, t1, 0x0C
	j 1b
2:	ret

.globl delayus
# a0 has delay in microseconds
delayus:
	addi sp, sp, -12
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)

	li t0, SIO_BASE
	lw t1, _MTIME(t0)
	add t2, t1, a0
1:	lw t1, _MTIME(t0)
	blt t1, t2, 1b  	# NOTE this will give a short timeout if mtime+tmo has wrapped

	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	addi sp, sp, 12
	ret

.globl delayms
# a0 has delay in milliseconds
delayms:
	li t1, 1000
	mul a0, a0, t1
	j delayus
