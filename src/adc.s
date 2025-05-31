.equ ADC_BASE, 0x400a0000
  .equ _CS, 0x00000000
    .equ b_CS_EN, 1<<0
    .equ b_CS_TS_EN, 1<<1
    .equ b_CS_START_ONCE, 1<<2
    .equ b_CS_START_MANY, 1<<3
    .equ b_CS_READY, 1<<8
    .equ b_CS_ERR, 1<<9
    .equ b_CS_ERR_STICKY, 1<<10
    .equ m_CS_AINSEL, 0x0000F000
    .equ o_CS_AINSEL, 12
    .equ m_CS_RROBIN, 0x01FF0000
    .equ o_CS_RROBIN, 16
  .equ _RESULT, 0x00000004
    .equ m_RESULT_RESULT, 0x00000FFF
    .equ o_RESULT_RESULT, 0
  .equ _FCS, 0x00000008
    .equ b_FCS_EN, 1<<0
    .equ b_FCS_SHIFT, 1<<1
    .equ b_FCS_ERR, 1<<2
    .equ b_FCS_DREQ_EN, 1<<3
    .equ b_FCS_EMPTY, 1<<8
    .equ b_FCS_FULL, 1<<9
    .equ b_FCS_UNDER, 1<<10
    .equ b_FCS_OVER, 1<<11
    .equ m_FCS_LEVEL, 0x000F0000
    .equ o_FCS_LEVEL, 16
    .equ m_FCS_THRESH, 0x0F000000
    .equ o_FCS_THRESH, 24
  .equ _FIFO, 0x0000000c
    .equ m_FIFO_VAL, 0x00000FFF
    .equ o_FIFO_VAL, 0
    .equ b_FIFO_ERR, 1<<15
  .equ _DIV, 0x00000010
    .equ m_DIV_FRAC, 0x000000FF
    .equ o_DIV_FRAC, 0
    .equ m_DIV_INT, 0x00FFFF00
    .equ o_DIV_INT, 8
  .equ _INTR, 0x00000014
    .equ b_INTR_FIFO, 1<<0
  .equ _INTE, 0x00000018
    .equ b_INTE_FIFO, 1<<0
  .equ _INTF, 0x0000001c
    .equ b_INTF_FIFO, 1<<0
  .equ _INTS, 0x00000020
    .equ b_INTS_FIFO, 1<<0

.equ RESETS_BASE, 0x40020000
	.equ _RESET, 0x00000000
		.equ b_RESET_ADC, 1<<0
	.equ _RESET_DONE, 0x00000008
		.equ b_RESET_DONE_ADC, 1<<0

.equ GPIO_FUNC_NULL, 0x1f

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# Note set 2350A to 1 unless using 2350B which uses different pins 40-48
.equ PICO_RP2350A, 1

.if PICO_RP2350A
	.equ NUM_ADC_CHANNELS, 5
	.equ ADC_BASE_PIN, 26
.else
	.equ NUM_ADC_CHANNELS, 9
	.equ ADC_BASE_PIN, 40
.endif

.section .text

# initialize ADC
.globl adc_init
adc_init:
	# reset the peripheral
	li t1, RESETS_BASE
	li t0, b_RESET_ADC
	sw t0, _RESET(t1)
	sw zero, _RESET(t1)
1:	lw t2, _RESET_DONE(t1)
	andi t2, t2, b_RESET_DONE_ADC		# wait for reset
	beqz t2, 1b

	# turn it on
	li t0, ADC_BASE
	li t1, b_CS_EN
	sw t1, _CS(t0)
2:	lw t1, _CS(t0)
	andi t1, t1, b_CS_READY
	beqz t1, 2b
	ret

# enable adc on the gpio pin in a0, returns 1 in a0 if OK
.globl adc_gpio_init
adc_gpio_init:
	addi sp, sp, -4
  	sw ra, 0(sp)

	# check pin numbers
	li t0, ADC_BASE_PIN
	blt a0, t0, bad_pin
	li t0, ADC_BASE_PIN+NUM_ADC_CHANNELS
	bge a0, t0, bad_pin

	li a1, GPIO_FUNC_NULL
	call gpio_set_function
	call gpio_disable_pulls
	li a1, 0
	call gpio_set_input_enabled 	# disable input

1: 	lw ra, 0(sp)
  	addi sp, sp, 4
  	ret

bad_pin:
	mv a0, zero
	j 1b

# select the adc input in a0
.globl adc_select_input
adc_select_input:
	li t0, ADC_BASE
	lw t1, _CS(t0)
	li t2, ~(m_CS_AINSEL)
	and t1, t1, t2
	slli t2, a0, o_CS_AINSEL
	or t1, t1, t2
	sw t1, _CS(t0)
	ret

.globl adc_enable_temp
adc_enable_temp:
	li t0, ADC_BASE|WRITE_SET
	li t1, b_CS_TS_EN
	sw t1, _CS(t0)
	ret

# read adc when ready return raw value in a0
.globl adc_read
adc_read:
	li t0, ADC_BASE|WRITE_SET
	li t1, b_CS_START_ONCE
	sw t1, _CS(t0)
	li t0, ADC_BASE
1:	lw t1, _CS(t0)
	andi t1, t1, b_CS_READY
	beqz t1, 1b
	lhu a0, _RESULT(t0)
	li t0, m_RESULT_RESULT
	and a0, a0, t0
	ret

# 12-bit conversion, assume max value == ADC_VREF == 3.3 V
# conversion_factor = 3.3f / (1 << 12);
# raw adc in a0, return normalized in a0
.globl adc_normalize
adc_normalize:
	addi sp, sp, -4
  	sw ra, 0(sp)
	mv a3, a0
	li a0, 0x4CCCCCCC
	li a1, 0x00000003 	# 3.3
	li a2, 0
	call fpmul 			# adcraw * 3.3
	li a2, 0
	li a3, 1<<12		# 4096.0
	call fpdiv 			# (adcraw * 3.3) / 4096
 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.globl test_adc
test_adc:
	# j test_adc_as4

	call adc_init
	li a0, 26
	call adc_gpio_init
	li a0, 0
	call adc_select_input
1:	call adc_read
	mv s1, a0
	call uart_print4hex
	call uart_printspc
	mv a0, s1
	call adc_normalize
	call uart_printfp
	call uart_printnl
	li a0, 500
	call delayms
	j 1b

test_adc_temp:
	call adc_init
	call adc_enable_temp
	li a0, 4
	call adc_select_input
1:	call adc_read
	call adc_normalize 	# adc
	# float tempC = 27.0f - (adc - 0.706f) / 0.001721000
	li a2, 0xB4BC6A7E
	li a3, 0x00000000 	# 0.706000000
	call fpsub
	li a2, 0x0070C996
	li a3, 0x00000000 	# 0.001721000
	call fpdiv
	mv a2, a0
	mv a3, a1
	li a0, 0
	li a1, 27
	call fpsub
	call uart_printfp
	call uart_printnl
	li a0, 1000
	call delayms
	j 1b

test_adc_as4:
	call adc_init
	li a0, 26
	call adc_gpio_init
	li a0, 0
	call adc_select_input

1:	call adc_read
	# we get a value between 0 and 4095 (12 bits) which is 0 to 359 degrees
	li t1, 36000
	mul t0, a0, t1
	li t1, 4096
	div a0, t0, t1
	call uart_printn
	call uart_printnl
	li a0, 500
	call delayms
	j 1b


