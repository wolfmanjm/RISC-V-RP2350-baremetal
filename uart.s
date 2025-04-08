.section .text

.macro pushra
  	addi sp, sp, -4
  	sw ra, 0(sp)
.endm

.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, 4
.endm

.equ  RESETS_RESET, 0x40020000

.equ IO_BANK0_BASE, 0x40028000
.equ GPIO_0_CTRL, IO_BANK0_BASE + (8 * 0) + 4
.equ GPIO_1_CTRL, IO_BANK0_BASE + (8 * 1) + 4
.equ PADS_BANK0_BASE, 0x40038000
.equ GPIO_0_PAD,     PADS_BANK0_BASE + 0x04
.equ GPIO_1_PAD,     PADS_BANK0_BASE + 0x08

.equ UART0_BASE, 0x40070000
.equ _UART0_DR   , 0x00 # Data Register, UARTDR
.equ _UART0_RSR  , 0x04 # Receive Status Register/Error Clear Register, UARTRSR/UARTECR
.equ _UART0_FR   , 0x18 # Flag Register, UARTFR
.equ _UART0_ILPR , 0x20 # IrDA Low-Power Counter Register, UARTILPR
.equ _UART0_IBRD , 0x24 # Integer Baud Rate Register, UARTIBRD
.equ _UART0_FBRD , 0x28 # Fractional Baud Rate Register, UARTFBRD
.equ _UART0_LCR_H, 0x2c # Line Control Register, UARTLCR_H
.equ _UART0_CR   , 0x30 # Control Register, UARTCR
.equ _UART0_IFLS , 0x34 # Interrupt FIFO Level Select Register, UARTIFLS
.equ _UART0_IMSC , 0x38 # Interrupt Mask Set/Clear Register, UARTIMSC
.equ _UART0_RIS  , 0x3c # Raw Interrupt Status Register, UARTRIS
.equ _UART0_MIS  , 0x40 # Masked Interrupt Status Register, UARTMIS
.equ _UART0_ICR  , 0x44 # Interrupt Clear Register, UARTICR
.equ _UART0_DMACR, 0x48 # DMA Control Register, UARTDMACR

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# 115200 baud 81.38 with sysclk
.equ UART_IBAUD, 81
.equ UART_FBAUD, 24
.equ UART_8N1, 3 << 5
.equ UART_FIFO, 1 << 4
.equ UART_ENABLE, 1<<9|1<<8|1<<0

# sets GPIO0 and GPIO1 for TX/RX Fnc2 on UART0
.globl uart_init
uart_init:
	li t1, RESETS_RESET
	li t0, 1<<26		# uart set reset
	sw t0, 0(t1)
	sw zero, 0(t1)
1:	lw t2, 8(t1)		# RESETS_RESET_DONE
	and t2, t2, t0		# wait for reset
	beqz t2, 1b

	# enable pins
	li t0, GPIO_0_CTRL   # TX
	li t1, 2
	sw t1, 0(t0)

	li t0, GPIO_1_CTRL   # RX
	li t1, 2
	sw t1, 0(t0)

	# Remove pad isolation control bits for the UART pins, and enable input on the RX wire
	li t0, GPIO_0_PAD   # TX
	li t1, 0
	sw t1, 0(t0)

	li t0, GPIO_1_PAD   # RX
	li t1, (1 << 6)
	sw t1, 0(t0)

	# set baud rate to 115200
	li t0, UART0_BASE
	li t1, UART_IBAUD
	sw t1, _UART0_IBRD(t0)
	li t1, UART_FBAUD
	sw t1, _UART0_FBRD(t0)
	# set to 8N1
	li t1, UART_8N1 | UART_FIFO
	sw t1, _UART0_LCR_H(t0)
	# enable uart
	li t1, UART_ENABLE
	sw t1, _UART0_CR(t0)
    ret

.globl uart_putc
uart_putc:
    li t0, UART0_BASE
1:  lw t1, _UART0_FR(t0)   # Read flag register
    andi t1, t1, 0x20      # Check if TX FIFO is full
    bnez t1, 1b            # Wait if full
    sb a0, _UART0_DR(t0)   # Write character to TX FIFO
    ret

.globl uart_puts
uart_puts:
	pushra
    mv t2, a0             # t2 = pointer to string
1:  lbu a0, 0(t2)         # Load character
    beqz a0, 2f           # If NULL terminator, exit
    call uart_putc        # Send character
    addi t2, t2, 1        # Move to next character
    j 1b
2:  popra
	ret

.globl uart_getc
uart_getc:
	li t0, UART0_BASE
1:	lw t1, _UART0_FR(t0)
	andi t1, t1, 0x10  		# UARTFR_RX_FIFO_EMPTY, Bit 4
	bnez t1, 1b
	lbu a0, _UART0_DR(t0)
	ret

.globl parse_n
parse_n:
	mv t0, a0
	li t2, 10
	la t3, tmpstr
1:	remu t1, t0, t2
	addi t1, t1, 0x30
	sb t1, 0(t3)
	addi t3, t3, 1
	divu t0, t0, t2
	bnez t0, 1b
	la t4, tmpstr
	mv t5, a1 			# destination address
	sub t2, t3, t4 		# number of characters
2:	addi t3, t3, -1     # copy into num string in reverse order
	lbu t1, 0(t3)
	sb t1, 0(t5)
	addi t5, t5, 1
	addi t2, t2, -1
	bnez t2, 2b
	sb zero, 0(t5)		# 0 terminate
	ret

.globl test_uart
test_uart:
	pushra
    call uart_init       # Initialize UART
    la a0, msg           # Load address of message
    call uart_puts       # Print message
    li a0, 1234567890
    la a1, numstr
    call parse_n
    la a0, numstr
    call uart_puts
    li a0, 10
    call uart_putc
    popra
    ret

.section .data
msg: .asciz "Hello, RISC-V UART!\n"
tmpstr: .dcb.b 16
numstr: .dcb.b 16
