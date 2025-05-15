.equ PWM_BASE, 0x400a8000
  .equ _CSR, 0x00000000
    .equ b_CSR_EN, 1<<0
    .equ b_CSR_PH_CORRECT, 1<<1
    .equ b_CSR_A_INV, 1<<2
    .equ b_CSR_B_INV, 1<<3
    .equ m_CSR_DIVMODE, 0x00000030
    .equ o_CSR_DIVMODE, 4
    .equ b_CSR_PH_RET, 1<<6
    .equ b_CSR_PH_ADV, 1<<7

  .equ _DIV, 0x00000004
    .equ m_DIV_FRAC, 0x0000000F
    .equ o_DIV_FRAC, 0
    .equ m_DIV_INT, 0x00000FF0
    .equ o_DIV_INT, 4

  .equ _CTR, 0x00000008
    .equ m_CTR_CTR, 0x0000FFFF
    .equ o_CTR_CTR, 0

  .equ _CC, 0x0000000c
    .equ m_CC_A, 0x0000FFFF
    .equ o_CC_A, 0
    .equ m_CC_B, 0xFFFF0000
    .equ o_CC_B, 16

  .equ _TOP, 0x00000010
    .equ m_TOP, 0x0000FFFF
    .equ o_TOP, 0

.equ IO_BANK0_BASE, 0x40028000   # pin# * 8
.equ GPIO_FUNC_PWM, 4

.equ PWM_DIV_FREE_RUNNING, 0 	# Free-running counting at rate dictated by fractional divider
.equ PWM_DIV_B_HIGH, 1       	# Fractional divider is gated by the PWM B pin
.equ PWM_DIV_B_RISING, 2     	# Fractional divider advances with each rising edge of the PWM B pin
.equ PWM_DIV_B_FALLING, 3     	# Fractional divider advances with each falling edge of the PWM B pin
.equ PWM_CHAN_A, 0
.equ PWM_CHAN_B, 1

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# DIV setting using TOP = 32768
.equ FREQ_50Hz, 0x05B9
.equ FREQ_60Hz, 0x04C5
.equ FREQ_100Hz, 0x02DC
.equ FREQ_1KHz, 0x0049
.equ FREQ_2KHz, 0x0025
.equ FREQ_4KHz, 0x0012

# typedef struct {
#     uint32_t csr;
#     uint32_t div;
#     uint32_t top;
# 	ptr slicebaseaddr
# 	bit CCA
# } pwm_config;

.section .text

# a0 pin, returns instance in a0 used for further calls
# by default this sets the frequency to 1KHz and the duty cycle to 50%
.globl pwm_init
pwm_init:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li a1, GPIO_FUNC_PWM
	call gpio_set_function
	li a1, 1
	call gpio_set_slew

	# slice_num = ((gpio) >> 1u) & 7u;
	slli t0, a0, 1
	andi t0, t0, 0x07

	# set TOP to 32768 and set DIV to 0x0049 = 1000Hz period
	li t1, PWM_BASE
	li t2, 0x14
	mul t0, t0, t2
	add t0, t0, t1
	li t1, 32768
	sw t1, _TOP(t0)
	li t1, 0x0049
	sw t1, _DIV(t0)

	# set to 50% duty cycle 32768/2 = 16384
	# NOTE this can only be A or B. FIXME
	li t1, 16384
	bexti t2, a0, 0 	# A or B?
	beqz t2, 1f
	slli t1, t1, o_CC_B
1:	sw t1, _CC(t0)

	# start it, NOTE this should really be a WRITE_SET, FIXME
	li t1, b_CSR_EN
	sw t1, _CSR(t0)

	# a0 will have the base address of the slice this pin belongs to
	mv a0, t0

  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# a0 instance
pwm_start:
	# start it
	li t0, WRITE_SET
	or t0, a0, t0
	li t1, b_CSR_EN
	sw t1, _CSR(t0)
	ret

# a0 instance
pwm_stop:
	# stop it
	li t0, WRITE_CLR
	or t0, a0, t0
	li t1, b_CSR_EN
	sw t1, _CSR(t0)
	ret

# a0 instance, a1 top, a2 div
pwm_set_frequency:
	sw a1, _TOP(a0)
	sw a2, _DIV(a0)
	ret

# a0 instance, a1 duty in percent*10 so 1000 is 100%, 500 is 50%, 1 is 0.1%
# FIXME Right now only works for even numbered pins
.globl pwm_set_duty
pwm_set_duty:
	li t2, 32768
	mul t3, t2, a1
	li t2, 1000
	div t0, t3, t2
#	bexti t2, a0, 0 	# A or B? FIXME need to determine channel
#	beqz t2, 1f
#	slli t1, t1, o_CC_B
1:	sw t0, _CC(a0)
	ret

.globl test_pwm
test_pwm:
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

	# to test the esc with PWM
	j test_pwm_esc

	# simple test just changes pin
1:	li a0, 1000
	call delayms

	mv a0, s1
	li a1, 1000 	# 100%
	call pwm_set_duty

	li a0, 1000
	call delayms

	mv a0, s1
	li a1, 500 	# 50%
	call pwm_set_duty

	li a0, 1000
	call delayms

	mv a0, s1
	li a1, 100 	# 10%
	call pwm_set_duty

	j 1b

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw s2, 8(sp)
  	addi sp, sp, 12
  	ret

test_pwm_esc:
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
