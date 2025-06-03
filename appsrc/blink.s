.section .text

.macro pushra
  	addi sp, sp, -4
  	sw ra, 0(sp)
.endm

.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, 4
.endm

.globl blink_init
blink_init:
	pushra
	li a0, 25
	call pin_output
	popra
	ret

.globl blink_test
blink_test:
	call blink_init
1:	li a0, 25
	call pin_high
	li a0, 700
	call delayms
	li a0, 25
	call pin_low
	li a0, 300
	call delayms
    j 1b

.globl blink_led
blink_led:
	pushra
	beqz a0, led_off
	li a0, 25
	call pin_high
	popra
	ret
led_off:
	pushra
	li a0, 25
	call pin_low
	popra
	ret
