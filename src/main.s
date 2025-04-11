.section .text

.globl main
main:
	# call setup_uart
	# call spi1_init
	# call toggle_pin
	# call test_uart
	call blink

	ebreak

	wfi                 # Wait for interrupt (to save power)
2:  j 2b
