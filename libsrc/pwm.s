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
.globl pwm_set_frequency
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

