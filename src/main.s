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
	# call test_breakout
	call test_spi

	ebreak

	wfi                 # Wait for interrupt (to save power)
2:  j 2b
