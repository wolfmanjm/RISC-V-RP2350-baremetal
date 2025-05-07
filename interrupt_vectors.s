.equ TIMER0_IRQ_0, 0 # Select TIMER0's IRQ 0 output
.equ TIMER0_IRQ_1, 1 # Select TIMER0's IRQ 1 output
.equ TIMER0_IRQ_2, 2 # Select TIMER0's IRQ 2 output
.equ TIMER0_IRQ_3, 3 # Select TIMER0's IRQ 3 output
.equ TIMER1_IRQ_0, 4 # Select TIMER1's IRQ 0 output
.equ TIMER1_IRQ_1, 5 # Select TIMER1's IRQ 1 output
.equ TIMER1_IRQ_2, 6 # Select TIMER1's IRQ 2 output
.equ TIMER1_IRQ_3, 7 # Select TIMER1's IRQ 3 output
.equ PWM_IRQ_WRAP_0, 8 # Select PWM's IRQ_WRAP 0 output
.equ PWM_IRQ_WRAP_1, 9 # Select PWM's IRQ_WRAP 1 output
.equ DMA_IRQ_0, 10 # Select DMA's IRQ 0 output
.equ DMA_IRQ_1, 11 # Select DMA's IRQ 1 output
.equ DMA_IRQ_2, 12 # Select DMA's IRQ 2 output
.equ DMA_IRQ_3, 13 # Select DMA's IRQ 3 output
.equ USBCTRL_IRQ, 14 # Select USBCTRL's IRQ output
.equ PIO0_IRQ_0, 15 # Select PIO0's IRQ 0 output
.equ PIO0_IRQ_1, 16 # Select PIO0's IRQ 1 output
.equ PIO1_IRQ_0, 17 # Select PIO1's IRQ 0 output
.equ PIO1_IRQ_1, 18 # Select PIO1's IRQ 1 output
.equ PIO2_IRQ_0, 19 # Select PIO2's IRQ 0 output
.equ PIO2_IRQ_1, 20 # Select PIO2's IRQ 1 output
.equ IO_IRQ_BANK0, 21 # Select IO_BANK0's IRQ output
.equ IO_IRQ_BANK0_NS, 22 # Select IO_BANK0_NS's IRQ output
.equ IO_IRQ_QSPI, 23 # Select IO_QSPI's IRQ output
.equ IO_IRQ_QSPI_NS, 24 # Select IO_QSPI_NS's IRQ output
.equ SIO_IRQ_FIFO, 25 # Select SIO's IRQ_FIFO output
.equ SIO_IRQ_BELL, 26 # Select SIO's IRQ_BELL output
.equ SIO_IRQ_FIFO_NS, 27 # Select SIO_NS's IRQ_FIFO output
.equ SIO_IRQ_BELL_NS, 28 # Select SIO_NS's IRQ_BELL output
.equ SIO_IRQ_MTIMECMP, 29 # Select SIO_IRQ_MTIMECMP's IRQ output
.equ CLOCKS_IRQ, 30 # Select CLOCKS's IRQ output
.equ SPI0_IRQ, 31 # Select SPI0's IRQ output
.equ SPI1_IRQ, 32 # Select SPI1's IRQ output
.equ UART0_IRQ, 33 # Select UART0's IRQ output
.equ UART1_IRQ, 34 # Select UART1's IRQ output
.equ ADC_IRQ_FIFO, 35 # Select ADC's IRQ_FIFO output
.equ I2C0_IRQ, 36 # Select I2C0's IRQ output
.equ I2C1_IRQ, 37 # Select I2C1's IRQ output
.equ OTP_IRQ, 38 # Select OTP's IRQ output
.equ TRNG_IRQ, 39 # Select TRNG's IRQ output
.equ PROC0_IRQ_CTI, 40 # Select PROC0's IRQ_CTI output
.equ PROC1_IRQ_CTI, 41 # Select PROC1's IRQ_CTI output
.equ PLL_SYS_IRQ, 42 # Select PLL_SYS's IRQ output
.equ PLL_USB_IRQ, 43 # Select PLL_USB's IRQ output
.equ POWMAN_IRQ_POW, 44 # Select POWMAN's IRQ_POW output
.equ POWMAN_IRQ_TIMER, 45 # Select POWMAN's IRQ_TIMER output
.equ SPARE_IRQ_0, 46 # Select SPARE IRQ 0
.equ SPARE_IRQ_1, 47 # Select SPARE IRQ 1
.equ SPARE_IRQ_2, 48 # Select SPARE IRQ 2
.equ SPARE_IRQ_3, 49 # Select SPARE IRQ 3
.equ SPARE_IRQ_4, 50 # Select SPARE IRQ 4
.equ SPARE_IRQ_5, 51 # Select SPARE IRQ 5

# GPIO events must be set to one or all of these
.equ b_INTR_LEVEL_LOW, 1<<0
.equ b_INTR_LEVEL_HIGH, 1<<1
.equ b_INTR_EDGE_LOW, 1<<2
.equ b_INTR_EDGE_HIGH, 1<<3
