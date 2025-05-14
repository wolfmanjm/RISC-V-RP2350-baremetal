.section .text

.globl main
main:
	# call setup_uart
	# call toggle_pin
	# call test_uart
	# call blink_test
	# call test_alarm
	# call test_multi_core
	# call test_gpio
	# call test_gpio_irq
	# call test_breakout
	# call test_spi
	# call test_rotary
	# call test_tft
	call test_pwm
	ebreak

2:	wfi                 # Wait for interrupt (to save power)
	j 2b
