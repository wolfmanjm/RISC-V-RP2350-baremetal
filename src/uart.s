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

.equ GPIO_FUNC_UART, 2

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
	li t1, GPIO_FUNC_UART
	sw t1, 0(t0)

	li t0, GPIO_1_CTRL   # RX
	li t1, GPIO_FUNC_UART
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

	# clear rx fifo
	li t0, UART0_BASE
2:	lw t1, _UART0_FR(t0)
	andi t1, t1, 0x10  		# UARTFR_RX_FIFO_EMPTY, Bit 4
	bnez t1, 3f
	lbu t1, _UART0_DR(t0)
	j 2b

3:  ret

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

# returns a0 = 1 if character available else 0
.globl uart_qc
uart_qc:
	li t0, UART0_BASE
1:	lw t1, _UART0_FR(t0)
	andi t1, t1, 0x10  		# UARTFR_RX_FIFO_EMPTY, Bit 4
	beqz t1, 2f
	mv a0, zero
	ret
2: 	li a0, 1
	ret

# read in \n terminated string into address provided by a0, returns number of characters in a0
.globl uart_gets
uart_gets:
	pushra
	mv t2, a0
	mv t3, zero
1:  call uart_getc		# get character into a0
    mv t0, a0         	# t0 = char
    # check for newline or end of input
    li t1, '\n'
    beq t0, t1, 2f  	# if char == '\n', end input
    sb t0, 0(t2)
    addi t2, t2, 1
    addi t3, t3, 1
    j 1b
2:	sb zero, 0(t2)
	mv a0, t3
	popra
	ret

.globl uint2str
# a0 number to parse, a1 destination address for string
# terminates string with 0
# returns address of next character in a1
uint2str:
	mv t0, a0
	li t2, 10
	la t3, tmpstr
1:	remu t1, t0, t2
	addi t1, t1, 0x30
	sb t1, 0(t3)
	addi t3, t3, 1
	divu t0, t0, t2
	bnez t0, 1b
	la t2, tmpstr
	mv t0, a1 			# destination address
2:	addi t3, t3, -1     # copy into num string in reverse order
	lbu t1, 0(t3)
	sb t1, 0(t0)
	addi t0, t0, 1
	bne t3, t2, 2b
	sb zero, 0(t0)		# 0 terminate
	mv a1, t0
	ret

.globl int2str
int2str:
	bltz a0, 1f
	j uint2str
	# handle negative case
1:	pushra
	neg a0, a0
	li t0, '-'
	sb t0, 0(a1)
	addi a1, a1, 1
	call uint2str
2:	popra
	ret

.globl hex1_2str
# a0 has nibble to parse, a1 has address to put the string
# terminates string with 0
# on return a1 points to next character
hex1_2str:
	addi t0, a0, 0x30
	li t1, 0x39
	ble t0, t1, 1f
	addi t0, t0, 7
1:	sb t0, 0(a1)
	addi a1, a1, 1
	sb zero, 0(a1)
	ret

.globl hex2_2str
# a0 has byte to parse, a1 has address to put the string
# terminates string with 0
# on return a1 points to next character
hex2_2str:
	pushra
	srli t0, a0, 4
	andi t2, a0, 0x0F
	mv a0, t0
	call hex1_2str
	mv a0, t2
	call hex1_2str
	popra
	ret

.globl hex4_2str
# a0 has halfword to parse, a1 has address to put the string
# terminates string with 0
# on return a1 points to next character
hex4_2str:
	pushra
	andi t3, a0, 0xFF
	srli a0, a0, 8
	andi a0, a0, 0xFF
	call hex2_2str
	mv a0, t3
	call hex2_2str
	popra
	ret

.globl hex8_2str
# a0 has word to parse, a1 has address to put the string
# terminates string with 0
# on return a1 points to next character
hex8_2str:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	mv s1, a0
	srli a0, a0, 16
	call hex4_2str
	mv a0, s1
	call hex4_2str

 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
  	ret

# print hex byte in a0
.globl uart_print2hex
uart_print2hex:
	pushra
	la a1, numstr
	call hex2_2str
	la a0, numstr
	call uart_puts
	popra
	ret

# print hex word in a0
.globl uart_print8hex
uart_print8hex:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw a1, 8(sp)

	la a1, numstr
	call hex8_2str
	la a0, numstr
	call uart_puts

  	lw ra, 0(sp)
  	lw a0, 4(sp)
  	lw a1, 8(sp)
  	addi sp, sp, 12
	ret

# print number in a0
.globl uart_printn
uart_printn:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw a1, 8(sp)
	la a1, numstr
	call int2str
	la a0, numstr
	call uart_puts
 	lw ra, 0(sp)
  	lw a0, 4(sp)
  	lw a1, 8(sp)
  	addi sp, sp, 12
	ret

.globl uart_printun
uart_printun:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw a1, 8(sp)
	la a1, numstr
	call uint2str
	la a0, numstr
	call uart_puts
 	lw ra, 0(sp)
  	lw a0, 4(sp)
  	lw a1, 8(sp)
  	addi sp, sp, 12
	ret

.globl uart_printnl
uart_printnl:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
	sw a1, 8(sp)

	li a0, 10
	call uart_putc

  	lw ra, 0(sp)
  	lw a0, 4(sp)
 	lw a1, 8(sp)
  	addi sp, sp, 12
  	ret

.globl uart_printspc
uart_printspc:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw a0, 4(sp)
	sw a1, 8(sp)

	li a0, ' '
	call uart_putc

  	lw ra, 0(sp)
  	lw a0, 4(sp)
 	lw a1, 8(sp)
  	addi sp, sp, 12
  	ret

# convert the ihteger in string at a0, into an integer in a0
# only handles absolute so strip preceding - and negate after
.globl str2int
str2int:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s0, 4(sp)
  	# inialize
    li s0, 0 			# int = 0

1: 	lb t0, 0(a0)
	beqz t0, 4f
	addi a0, a0, 1
    # Convert ASCII to digit
	li t1, '0'
    sub t1, t0, t1    # t1 = digit (char - '0')
    li t0, 10
	mul s0, s0, t0
    add s0, s0, t1
    j 1b

4:	mv a0, s0
 	lw ra, 0(sp)
  	lw s0, 4(sp)
  	addi sp, sp, 8
    ret

# reads an integer from uart, handles negative numbers by skipping the -
# and negating at end if needed
.globl uart_getint
uart_getint:
	addi sp, sp, -4
  	sw ra, 0(sp)

1:	la a0, tmpstr
  	call uart_gets		# read line into tmpstr
  	bnez a0, 2f
  	li a0, 0 			# empty string
  	j 4f
2:	la a0, tmpstr
	lb t0, 0(a0)
	li t1, '-'
	bne t0, t1, 3f
	addi a0, a0, 1
3:	call str2int
	# check if it was negative
	la t0, tmpstr
	lb t0, 0(t0)
	li t1, '-'
	bne t0, t1, 4f
	neg a0, a0
4: 	lw ra, 0(sp)
  	addi sp, sp, 4
  	ret


.globl test_uart
test_uart:
	pushra
    call uart_init       # Initialize UART
    la a0, msg           # Load address of message
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

    popra
    ret

.section .data
msg: .asciz "Hello, RISC-V UART!\n"
tmpstr: .dcb.b 32
numstr: .dcb.b 32
