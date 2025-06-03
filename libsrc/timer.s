.section .text

.macro pushra
  	addi sp, sp, -4
  	sw ra, 0(sp)
.endm

.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, 4
.endm

.equ  RESETS_RESET, 0x40020000
.equ TIMER0_BASE, 0x400b0000
.equ TIMER1_BASE, 0x400b8000

.equ _TIMEHW, 0x00 # TIMER_TIMEHW
.equ _TIMELW, 0x04 # TIMER_TIMELW
.equ _TIMEHR, 0x08 # TIMER_TIMEHR
.equ _TIMELR, 0x0C # TIMER_TIMELR
.equ _TIMERAWH, 0x24
.equ _TIMERAWL, 0x28

.equ _ALARM0, 0x10 # TIMER_ALARM0
.equ _ALARM1, 0x14 # TIMER_ALARM0
.equ _ALARM2, 0x18 # TIMER_ALARM0
.equ _ALARM3, 0x1C # TIMER_ALARM0

.equ _INTR, 0x3C # TIMER_INTR
.equ _INTE, 0x40 # TIMER_INTE
.equ _INTF, 0x44 # TIMER_INTF
.equ _INTS, 0x48 # TIMER_INTS

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

.equ RVCSR_MEIEA_OFFSET, 0x00000be0
.equ RVCSR_MEIFA_OFFSET, 0x00000be2

.include "interrupt_vectors.s"

.globl set_alarm

# a0 alarm num (0-3), a1 address to execute, a2 time in us
# NOTE currently hardwired for alarm 0 a0 = 0
set_alarm:
  	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw a1, 8(sp)

	li t0, TIMER0_BASE | WRITE_SET
	li t1, 1
	sll t1, t1, a0
	sw t1, _INTE(t0)
	# set the address to execute when this interrupt is hit
	li a0, TIMER0_IRQ_0
	call set_irq_vector

	# Enable interrupt TIMER0_IRQ_0 + alarm num
	li t0, TIMER0_IRQ_0
	add a0, t0, a0
	li a1, 1
	call enable_irq
  	lw ra, 0(sp)
  	lw a0, 4(sp)
  	lw a1, 8(sp)
  	addi sp, sp, 12

	# setup timer alarm value
    li t0, TIMER0_BASE
    lw t1, _TIMERAWL(t0)
    add t1, t1, a2
    sh2add t0, a0, t0
    sw t1, _ALARM0(t0)
	ret

# a0 is alarm num to clear
.globl clear_alarm
clear_alarm:
    # hw_clear_bits(&timer_hw->intr, 1u << ALARM_NUM);
	li t0, TIMER0_BASE | WRITE_CLR
   	bset t1, zero, a0  			# bit to clear
	sw t1, _INTR(t0)

	# disable core interrupt too
   	bset t0, zero, a0  			# bit to set
	slli t0, t0, 16				# upper 16 bits are bit to clear, lower 5 bits are the window (0)
	csrc RVCSR_MEIEA_OFFSET, t0
	ret

