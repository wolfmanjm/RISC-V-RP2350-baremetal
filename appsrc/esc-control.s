.section .text
##############################################
# ESC control using PWM and encoder
.equ FREQ_50Hz, 0x05B9
.equ FREQ_60Hz, 0x04C5
.equ FREQ_100Hz, 0x02DC
.equ FREQ_1KHz, 0x0049
.equ FREQ_2KHz, 0x0025
.equ FREQ_4KHz, 0x0012

.globl main
main:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)

	li a0, 16
	call pwm_init
	mv s1, a0

	li a1, 32768
	li a2, FREQ_100Hz 			# 100Hz
	call pwm_set_frequency

	mv a0, s1
	li a1, 0 				# 0%
	call pwm_set_duty


	li a0, 14
	li a1, 15
	call rotary_init

	call ili9341_init
	li a0, 0
	call ili9341_clearscreen

	# initial setting at 10% or 1000us/1ms IDLE throttle
	call rotary_get_count
	la t0, lstcnt
	sw a0, 0(t0)
	li s2, 100 			# 10%
    la t0, percent
    sw s2, 0(t0)
    # set DC
   	mv a0, s1
	mv a1, s2
	call pwm_set_duty

    # display current percent, and pulse width pw = 0 - 10ms 10% = 1ms 20% = 2ms
1:	li a0, 0
	call tft_clear_line
	mv a0, s2 				# DC
	li a1, 0
	li a2, 0
    call tft_printn

    # display us on second line
	li a0, 1
	call tft_clear_line
	# convert % to us
	li t2, 10000
	mul t3, t2, s2
	li t2, 1000
	div a0, t3, t2
	li a1, 0
	li a2, 1
    call tft_printn

    # as encoder rotates inc or dec the percentage
2:	wfi
	call rotary_get_count
    la t0, lstcnt 		# see if changed
    lw t1, 0(t0)
    beq a0, t1, 2b
    # get differential
    sub t2, a0, t1
    sw a0, 0(t0) 		# update lstcnt
    la t0, percent
    lw t1, 0(t0)
    add t1, t1, t2
    bgez t1, 4f
	mv t1, zero
4:  li t2, 1000
  	ble t1, t2, 3f
  	mv t1, t2

  	# number is good 0 >= x <= 1000
3:  sw t1, 0(t0)		# update percent
    # set DC
   	mv a0, s1
	mv a1, t1
	call pwm_set_duty
	mv s2, a1
	j 1b

.section .data
.p2align 2
lstcnt: .word 0
percent: .word 0
