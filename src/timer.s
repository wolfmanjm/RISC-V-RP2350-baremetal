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

# a0 alarm num, a1 address to execute, a2 timeus
# NOTE currently hardwired for alarm 0 a0 = 0
set_alarm:
	li t0, TIMER0_BASE | WRITE_SET
	li t1, 1
	sll t1, t1, a0
	sw t1, _INTE(t0)
	# set the address to execute when this interrupt is hit
	la t0, __soft_vector_table
	sw a1, TIMER0_IRQ_0(t0)

	# Enable interrupt...

	#   irq_set_mask_n_enabled(num / 32, 1u << (num % 32), enabled);
	#    if (enabled) {
    #     hazard3_irqarray_clear(RVCSR_MEIFA_OFFSET, 2 * n, mask & 0xffffu);
    #     hazard3_irqarray_clear(RVCSR_MEIFA_OFFSET, 2 * n + 1, mask >> 16);
    #     hazard3_irqarray_set(RVCSR_MEIEA_OFFSET, 2 * n, mask & 0xffffu);
    #     hazard3_irqarray_set(RVCSR_MEIEA_OFFSET, 2 * n + 1, mask >> 16);
    #    } else {
    #     hazard3_irqarray_clear(RVCSR_MEIEA_OFFSET, 2 * n, mask & 0xffffu);
    #     hazard3_irqarray_clear(RVCSR_MEIEA_OFFSET, 2 * n + 1, mask >> 16);
    #    }
    # (a0/16) | (1<<(a0%16))
	li t0, (0 | (1 << 16))
	csrc RVCSR_MEIFA_OFFSET, t0
	csrc RVCSR_MEIFA_OFFSET, zero
	csrs RVCSR_MEIEA_OFFSET, t0

    li t0, TIMER0_BASE
    lw t1, _TIMERAWL(t0)
    add t1, t1, a2
    sw t1, _ALARM0(t0)
	ret

# a0 is alarm num to clear
clear_alarm:
    # hw_clear_bits(&timer_hw->intr, 1u << ALARM_NUM);
	li t0, TIMER0_BASE | WRITE_CLR
	li t1, 1
	sll t1, t1, a0
	sw t1, _INTR(t0)

	# disable interrupt too
	li t0, (0 | (1 << 16))
	csrs RVCSR_MEIEA_OFFSET, t0

	ret

test_alarm_hit:
	li a0, 0
	pushra
	call clear_alarm
	popra

	la t0, alarm_flag
	li t1, 1
	sw t1, 0(t0)

	ret

# blink led once every second when alarm fires
.globl test_alarm
test_alarm:
	call blink_init

2:	la t0, alarm_flag
	sw zero, 0(t0)

	li a0, 0
	la a1, test_alarm_hit
	li a2, 1000000 # 1 second
	pushra
	call set_alarm
	popra

	# wait for alarm
	la t0, alarm_flag
1:	lw t1, 0(t0)
	beqz t1, 1b

	la t1, led_toggle
	lw t0, 0(t1)
	addi t0, t0, 1
	sw t0, 0(t1)
	andi a0, t0, 1
	call blink_led

	j 2b

.section .data
alarm_flag: .word 0
led_toggle: .word 0
