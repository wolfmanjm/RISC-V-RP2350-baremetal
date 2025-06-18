.section .text

.globl blink_init
blink_init:
 	addi sp, sp, -4
  	sw ra, 0(sp)
	li a0, 25
	call pin_output
  	lw ra, 0(sp)
  	addi sp, sp, 4
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
 	addi sp, sp, -4
  	sw ra, 0(sp)
	beqz a0, led_off
	li a0, 25
	call pin_high
  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret
led_off:
 	addi sp, sp, -4
  	sw ra, 0(sp)
	li a0, 25
	call pin_low
  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret
