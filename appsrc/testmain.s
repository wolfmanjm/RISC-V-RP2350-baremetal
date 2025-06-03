.section .text

# uncomment the test you want to run
.globl main
main:
	# call toggle_pin
	call test_uart
	# call blink_test
	# call test_alarm
	# call test_multi_core
	# call test_gpio
	# call test_gpio_irq
	# call test_breakout
	# call test_spi
	# call test_rotary
	# call test_tft
	# call test_pwm
	# call i2c_scan
	# call test_imu
	# call test_fp
	# call test_read_fp
	# call test_div64
	# call test_neopixel
	# call test_adc
	ebreak

2:	wfi                 # Wait for interrupt (to save power)
	j 2b

###########################################
# ADC tests

test_adc:
	call uart_init
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

###################################################
# div64 tests

test_div64:
	addi sp, sp, -4
  	sw ra, 0(sp)

	call uart_init
	# test divide
	li a0, 0x00010000
	li a1, 32767
	li a2, 65536
	call div64s
	call uart_print8hex
	call uart_printspc
	call uart_printn
	call uart_printnl

	# test multiply
	li a0, 65536
	li a1, 65536
	li a2, 65536
	call mul64_div
	call uart_print8hex
	call uart_printspc
	call uart_printn
	call uart_printnl

 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

###################################################
# fixed point tests

# macro to create a Fixed point constant params are:
# integer part fractional part, decimal places (10 == .1, 100 = 0.01, etc)
.macro FPCONST HW LW PREC
	li a0, (\LW * (1<<32)) / \PREC
	li a1, \HW
.endm
# FPCONST 1 1234 10000  # for 1.1234

test_fp:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	call uart_init

	FPCONST 1 1234 10000
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl

	li a0, 0x1999999A
	li a1, 0
	call uart_printfp
	call uart_printnl

	li a0, 0
	li a1, 1234
	call uart_printfp
	call uart_printnl

	li a0, 0x80000000
	li a1, 1234
	call uart_printfp
	call uart_printnl

	# 3.14159265
	li a0, 0x243F6A79
	li a1, 0x00000003
	call uart_printfp
	call uart_printnl

	# -3.14159265
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	call uart_printfp
	call uart_printnl

	# -1
	li a0, 0x00000000
	li a1, 0xFFFFFFFF
	call uart_printfp
	call uart_printnl

	# -123.456 -> 123.456
	li a0, 0x8B439582
	li a1, 0xFFFFFF84
	call fpabs
	call uart_printfp
	call uart_printnl

	# 0.273
	li a0, 0x45E353F8
	li a1, 0
	call uart_printfp
	call uart_printnl

	# 0.785398163 PI/4
	li a0, 0xC90FDAA2
	li a1, 0
	call uart_printfp
	call uart_printnl

	# 0.273 * 100 == 27.3
	li a0, 0x45E353F8
	li a1, 0
	li a2, 0
	li a3, 100
	call fpmul
	call uart_printfp
	call uart_printnl

	# 0.01 * 10 = 0.1 = 0x00000000_1999999A
	li a0, 0x028F5C29
	li a1, 0
	li a2, 0
	li a3, 10
	call fpmul
	call uart_printfp
	call uart_printnl

	# 0.1 / 10 = 0.01 = 0x00000000_028F5C29
	li a0, 0x1999999A
	li a1, 0
	li a2, 0
	li a3, 10
	call fpdiv
	call uart_printfp
	call uart_printnl


	# 0 - 3.14159265 == -3.14159265
	li a0, 0
	li a1, 0
	li a2, 0x243F6A79
	li a3, 0x00000003
	call fpsub
	call uart_printfp
	call uart_printnl

	# -3.14159265 + 3.14159265 == 0
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	li a2, 0x243F6A79
	li a3, 0x00000003
	call fpadd
	call uart_printfp
	call uart_printnl

	# neg 3.141592 == -3.141592
	li a0, 0x243F6A79
	li a1, 0x00000003
	call fpneg
	call uart_printfp
	call uart_printnl

	# neg -3.141592 == 3.141592
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	call fpneg
	call uart_printfp
	call uart_printnl

	# 0.1 / 1.0028 == 0.099720781 0x00000000_19874D18
	li a0, 0x19999999
	li a1, 0
	li a2, 0x00B78034
	li a3, 1
	call fpdiv
	call uart_printfp
	call uart_printnl

	# result == 0.0997
	li a0, 0x19999999
	li a1, 0
	li a2, 0
	li a3, 1
	call fp_atan2
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl


1: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret

test_read_fp:
1:	call uart_getfp
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl
	j 1b

###################################################
# GPIO tests
# GPIO events must be set to one or all of these

.equ b_INTR_LEVEL_LOW, 1<<0
.equ b_INTR_LEVEL_HIGH, 1<<1
.equ b_INTR_EDGE_LOW, 1<<2
.equ b_INTR_EDGE_HIGH, 1<<3


# Test routines
test_gpio:
	li a0, 25
	call pin_output

	li a0, 15
	call pin_input_pu

	# if pin15 is high then set pin25 high etc
1:	li a0, 15
	call delayms
	li a0, 15
	call pin_get
	beqz a0, 2f
	li a0, 25
	call pin_high
	j 1b

2:	li a0, 25
	call pin_low
	j 1b

.globl test_breakout
test_breakout:
	# set pins to outputs
	la s0, led_pins
1:	lw a0, 0(s0)
	beqz a0, 2f
	call pin_output
	addi s0, s0, 4
	j 1b

	# toggle each pin on or off
2:	la s0, led_pins
1:	lw a0, 0(s0)
	beqz a0, 3f
	call pin_toggle
	addi s0, s0, 4
	li a0, 100
	call delayms
	j 1b

3: 	j 2b

test_gpio_int_handler:
  	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw t0, 8(sp)
  	sw t1, 12(sp)

  	# increment count
  	la t1, irq_count
  	lw t0, 0(t1)
  	addi t0, t0, 1
  	sw t0, 0(t1)

    lw ra, 0(sp)
    lw a0, 4(sp)
  	lw t0, 8(sp)
  	lw t1, 12(sp)
	addi sp, sp, 16
	ret


.globl test_gpio_irq
test_gpio_irq:
	li a0, 25
	call pin_output
	li a0, 15
	call pin_input_pu

	# disable the commoninterrupt until all have been setup
	call gpio_disable_common_irq
	li a0, 15
	la a1, test_gpio_int_handler
	li a2, b_INTR_EDGE_HIGH
	call gpio_enable_interrupt
	# check a0 is 1
	bnez a0, 3f
	ebreak

3:	call gpio_enable_common_irq
	# toggles pin 25 depending on count LSB
1:	wfi
	li a0, 25
 	la t1, irq_count
  	lw t0, 0(t1)
 	andi t0, t0, 1
  	beqz t0, 2f
	call pin_high
	j 1b
2:	call pin_low
	j 1b

	ret

.section .data
led_pins:
	.word 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 26, 27, 28, 0

irq_count: .word 0

##################################################
# TFT tests

test_tft:
	call ili9341_init

	j test_tft_char

1:	li a0, 0
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0xFF0000
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0x00FF00
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0x0000FF
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0xFFFFFF
	call rgb_888_565
	mv a4, a0

	li a0, 20
	li a1, 20+20-1
	li a2, 20
	li a3, 20+20-1
	call ili9341_fillrect
	li a0, 1000
	call delayms

	j 1b
	ret


.equ FONT16_WIDTH, 11
.equ FONT16_HEIGHT, 16
.equ FONT16_STRIDE, 2

test_tft_char:
	# call ili9341_init

	li a0, 0
	call ili9341_clearscreen

	# set color for font
	li a0, 0xFFFFFF
	call rgb_888_565
	la t1, fg_color
	sh a0, 0(t1)
	li a0, 0x000000
	call rgb_888_565
	la t1, bg_color
	sh a0, 0(t1)

	# display all characters
	li s1, ' '	# char
	li s2, 0 	# x
	li s3, 20 	# y
	li s4, 16 	# cnt/line

1:	mv a0, s1
	mv a1, s2
	mv a2, s3
	call tft_putchar

	addi s1, s1, 1
	li t0, '~'
	bgt s1, t0, 2f
	addi s2, s2, FONT16_WIDTH
	addi s4, s4, -1
	bnez s4, 1b
	li s2, 0
	addi s3, s3, FONT16_HEIGHT
	li s4, 16
	j 1b

2:	la a0, hello_string
	li a1, 0
	li a2, 0
	call tft_printstr

	la a0, str2
	li a1, 0
	li a2, 10
	call tft_printstr

	la a0, hello_string
	call tft_printstr
	li a0, 2000
	call delayms

	li s1, 0
4:	mv a0, s1
	li a1, 0
	li a2, 12
	call tft_printn
	addi s1, s1, 1
	li t0, 100
	bne t0, s1, 5f
	li a0, 11
	call tft_clear_line
5:	li a0, 50
	call delayms
	j 4b

3:	j 3b
	ret

.section .rodata
hello_string: .asciz "Hello World!"
str2: .asciz "One Line\nNext line"

.section text
#####################################################
# IMU tests

test_imu:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)

	call i2c_init
	call uart_init       # Initialize UART

    la a0, msg1          # Load address of message
    call uart_puts       # Print message

    call who_am_i
	call uart_print2hex

    # la a0, msg2          # Load address of message
    # call uart_puts       # Print message
    # call read_temp
	# call uart_print2hex
	call uart_printnl

	call gyro_init
	bnez a0, 2f
	call acc_mag_init
	bnez a0, 2f

	# read gyro, acc, mag until key press
1:	la a0, msg3
	call uart_puts
	call read_gyro
	mv s1, a1
	mv s2, a2
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s1
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s2
	call uart_printn

	la a0, msg5
	call uart_puts
	call read_acc
	mv s1, a1
	mv s2, a2
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s1
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s2
	call uart_printn

	la a0, msg6
	call uart_puts
	call read_mag
	mv s1, a1
	mv s2, a2
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s1
	call uart_printn
	li a0, ','
	call uart_putc
	mv a0, s2
	call uart_printn

	# wait a while
	li a0, 300
	call delayms

	call uart_qc
	beqz a0, 1b
	j 3f

2:	la a0, msg4
	call uart_puts

3: 	lw ra, 0(sp)
 	lw s1, 4(sp)
 	lw s2, 8(sp)
  	addi sp, sp, 12
	ret

.section .data
msg1: .asciz "IMU Test\nWho am i: "
msg2: .asciz "\nTemp: "
msg3: .asciz "\nGyro: "
msg4: .asciz "\nThere was a read error\n"
msg5: .asciz " Acc: "
msg6: .asciz " Mag: "

.section .text

#########################################################
# NEOPIXEL tests

test_neopixel:
	call init_neopixel

	# select test
	j 2f

	# test timing
# 1:	call np_one
# 	call np_zero
# 	j 1b

# test one rgb
2: 	li a0, 255
	li a1, 0
	li a2, 0
	call np_send_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 0
 	li a1, 255
 	li a2, 0
	call np_send_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 0
	li a1, 0
 	li a2, 255
	call np_send_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 255
	li a1, 255
 	li a2, 255
	call np_send_rgb
	call np_reset
	li a0, 1000
	call delayms
	j 2b

# test string of 8 binary count each led
# color of each led is in the led_color table, the GRB color being in each word for each led
3:	li t5, 0  # each bit is the state of each led on/off
4:	li t6, 7
	# for each led test on/off
1:	bext t0, t5, t6
	beqz t0, 2f
	la t0, led_color
	sh2add t0, t6, t0
	lw a0, 0(t0)
	j 3f
2:	mv a0, zero
3:	call np_send
	addi t6, t6, -1
	bgez t6, 1b
	# increment count
	call np_reset
	addi t5, t5, 1
	li a0, 50
	call delayms
	j 4b

.section .data
.p2align 2
led_color: .word 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0xF0F0F0

.section .text
##############################################
# PWM tests
.equ FREQ_50Hz, 0x05B9
.equ FREQ_60Hz, 0x04C5
.equ FREQ_100Hz, 0x02DC
.equ FREQ_1KHz, 0x0049
.equ FREQ_2KHz, 0x0025
.equ FREQ_4KHz, 0x0012

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

#############################################
# rotary encoder tests

test_rotary:
	li a0, 15
	li a1, 14
	call rotary_init

	call uart_init       # Initialize UART
    la a0, msg           # Load address of message
    call uart_puts       # Print message

1:	wfi
	call rotary_get_count
    la t1, lstcnt 		# if changed then print
    lw t2, 0(t1)
    beq a0, t2, 1b
    sw a0, 0(t1) 		# update lstcnt
    call uart_printn
    call uart_printnl
    j 1b

	ret

.section .data
.p2align 2
#lstcnt: .word 0
numstr: .dcb.b 32
msg: .asciz "Rotary Encoder test on pins 14, 15\n"
.section .text

#######################################################
# TIMER/AARM tests

# note for IRQs we need to save all registers we use in here
alarm_irq:
  	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw t0, 8(sp)
  	sw t1, 12(sp)

	li a0, 0
	call clear_alarm

	la t0, alarm_flag
	li t1, 1
	sw t1, 0(t0)

    lw ra, 0(sp)
    lw a0, 4(sp)
  	lw t0, 8(sp)
  	lw t1, 12(sp)
	addi sp, sp, 16

	ret


# blink led once every second when alarm fires
.globl test_alarm
test_alarm:
	li a0, 25
	call pin_output

2:	la t0, alarm_flag
	sw zero, 0(t0)

	li a0, 0
	la a1, alarm_irq
	li a2, 1000000 # 1 second
	call set_alarm

	# wait for alarm
	la t0, alarm_flag
1:	lw t1, 0(t0)
	beqz t1, 1b

	la t1, led_toggle
	lw t0, 0(t1)
	addi t0, t0, 1
	sw t0, 0(t1)
	andi a0, t0, 1
	beqz a0, led_off
	li a0, 25
	call pin_high
	j 2b

led_off:
	li a0, 25
	call pin_low
	j 2b

.section .data
alarm_flag: .word 0
led_toggle: .word 0
.section .text

################################################
# UART tests

test_uart:
    call uart_init       # Initialize UART
    la a0, uart_msg           # Load address of message
    call uart_puts       # Print message

    li a0, 1234567890
    la a1, numstr
    call int2str
    la a0, numstr
    call uart_puts
    li a0, 10
    call uart_putc

    la a1, numstr
    li a0, 0x1234
    call hex4_2str
    li a0, 0x5678
    call hex4_2str
    li a0, 0x9ABC
    call hex4_2str
    li a0, 0xDEF0
    call hex4_2str
    la a0, numstr
    call uart_puts
    call uart_printnl

    la a1, numstr
    li a0, 0xFEDCBA98
    call hex8_2str
    la a0, numstr
    call uart_puts
    li a0, 0x20
    call uart_putc

    la a1, numstr
    li a0, 0x76543210
    call hex8_2str
    la a0, numstr
    call uart_puts
    li a0, 10
    call uart_putc

    li a0, 3
    call uart_printn
    call uart_printspc
    li a0, -3
    call uart_printn
    call uart_printnl

1:  li a0, '>'
    call uart_putc
    call uart_getint
    call uart_printn
    call uart_printnl
    j 1b


.section .data
uart_msg: .asciz "Hello, RISC-V UART!\n"

