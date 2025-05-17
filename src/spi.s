	.equ  SPI1_BASE, 0x40088000
	.equ  _SSPCR0, 0x00 	# Control register 0, SSPCR0 on page 3-4
	.equ  _SSPCR1, 0x04 	# Control register 1, SSPCR1 on page 3-5
	.equ  _SSPDR,  0x08		# Data register, SSPDR on page 3-6
	.equ  _SSPSR,  0x0C		# Status register, SSPSR on page 3-7
	.equ  _SSPCPSR, 0x10 	# Clock prescale register, SSPCPSR on page 3-8
	.equ  _SSPIMSC, 0x14 	# Interrupt mask set or clear register, SSPIMSC on page 3-9
	.equ  _SSPRIS,  0x18	# Raw interrupt status register, SSPRIS on page 3-10
	.equ  _SSPMIS,  0x1C	# Masked interrupt status register, SSPMIS on page 3-11
	.equ  _SSPICR,  0x20	# Interrupt clear register, SSPICR on page 3-11

 	# bitfields for SSPCR0
    .equ m_SSPCR0_DSS, 0x0000000F
    .equ o_SSPCR0_DSS, 0
    .equ m_SSPCR0_FRF, 0x00000030
    .equ o_SSPCR0_FRF, 4
    .equ m_SSPCR0_SCR, 0x0000FF00
    .equ o_SSPCR0_SCR, 8
    .equ b_SSPCR0_SPH, 1<<7
    .equ b_SSPCR0_SPO, 1<<6
    # bitfields for SSPCR1
    .equ b_SSPCR1_LBM, 1<<0
    .equ b_SSPCR1_SSE, 1<<1
    .equ b_SSPCR1_MS, 1<<2
    .equ b_SSPCR1_SOD, 1<<3
    # bitfields for SSPCPSR
    .equ m_SSPCPSR_CPSDVSR, 0x000000FF
    .equ o_SSPCPSR_CPSDVSR, 0
    # bitfields for SR
    .equ b_SSPSR_TFE, 1<<0
    .equ b_SSPSR_TNF, 1<<1
    .equ b_SSPSR_RNE, 1<<2
    .equ b_SSPSR_RFF, 1<<3
    .equ b_SSPSR_BSY, 1<<4
    # bitfields for SSPICR
    .equ b_SSPICR_RORIC, 1<<0
    .equ b_SSPICR_RTIC, 1<<1


	.equ  IO_BANK0_BASE, 0x40028000
	.equ  _GPIO_STATUS, 0x00  		# pin# * 8
	.equ  _GPIO_CTRL, 0x04

	.equ  PADS_BANK0_BASE, 0x40038000
    .equ _GPIO0, 0x00000004
	    .equ b_GPIO_SLEWFAST, 1<<0
	    .equ b_GPIO_SCHMITT, 1<<1
	    .equ b_GPIO_PDE, 1<<2
	    .equ b_GPIO_PUE, 1<<3
	    .equ m_GPIO_DRIVE, 0x00000030
	    .equ o_GPIO_DRIVE, 4
	    .equ b_GPIO_IE, 1<<6
	    .equ b_GPIO_OD, 1<<7
	    .equ b_GPIO_ISO, 1<<8


	.equ RESETS_BASE, 0x40020000
	.equ _RESETS_RESET, 0x000
	.equ _RESETS_RESET_DONE, 0x008
    .equ b_RESET_SPI1, 1<<19

	.equ GPIO_FUNC_SPI, 1 

	# cpol cpha
	.equ  SPI_MODE0, 0x00 
	.equ  SPI_MODE1, 0x01 
	.equ  SPI_MODE2, 0x10 
	.equ  SPI_MODE3, 0x11 

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write


	.equ CELL, 4

.macro pushra
  	addi sp, sp, -CELL
  	sw ra, 0(sp)
.endm

.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, CELL
.endm

.section .text

# reset SPI1
spi1_reset:
	li t1, RESETS_BASE
	li t0, b_RESET_SPI1		# set reset
	sw t0, _RESETS_RESET(t1)

	sw zero, _RESETS_RESET(t1)
1:	lw t2, _RESETS_RESET_DONE(t1)		# RESETS_RESET_DONE
	and t2, t2, t0						# begin 1<<19 RESETS_RESET_DONE bit@ until
	beqz t2, 1b
	ret

# set pins in a0, a1, a2 as SCLK, MOSI, MISO, to SPI function
spi_set_pins:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)

  	# save pins
  	mv s1, a1
  	mv s2, a2
  	li a1, GPIO_FUNC_SPI
  	call gpio_set_function
  	mv a0, s1
  	call gpio_set_function
  	mv a0, s2
  	call gpio_set_function

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw s2, 8(sp)
  	addi sp, sp, 12
  	ret

spi1_enable:
	li t1, SPI1_BASE
	lw t0, _SSPCR1(t1)
    beqz a0, 1f				# $02 SPI1_SSPCR1 rot if bis! else bic! then
	ori t0, t0, b_SSPCR1_SSE
	j 2f
1:	andi t0, t0, ~b_SSPCR1_SSE
2:  sw t0, _SSPCR1(t1)
	ret

# alternate using ATOMICs
# 		beqz a0, 1f
# 		li t1, SPI1_BASE|WRITE_SET
# 		j 2f
# 1:	li t1, SPI1_BASE|WRITE_CLR
# 2:	li t0, b_SSPCR1_SSE
# 		sw t0, _SSPCR1(t1)
# 		ret

# set SPI format a0 - #bits, a1 - mode
spi1_set_format:
	pushra
	mv t4, a0
	li a0, 0
	call spi1_enable

	addi t0, t4, -1
	andi t0, t0, 0xFF
	andi t1, a1, 0x03
	slli t1, t1, 6 			# SSPCR0_SPO | SSPCR0_SPH
	or  t0, t0	, t1
	li t3, 0b11001111  		# SSPCR0_SPO | SSPCR0_SPH | m_SSPCR0_DSS
	li t2, SPI1_BASE|WRITE_CLR
	sw t3, _SSPCR0(t2)		# clear bits
	li t2, SPI1_BASE|WRITE_SET
	sw t0, _SSPCR0(t2)  	# set bits

	li a0, 1
	call spi1_enable
	popra
	ret

# Hard coded to 4MHz
# to change set the 2 and 19 below to whatever find-spi-baudrate.cpp spits out for the requested baudrate
spi1_set_baudrate:
	pushra
	li a0, 0
	call spi1_enable

	# set prescale, clear first
	li t0, SPI1_BASE
	lw t1, _SSPCPSR(t0)
	li t2, ~(m_SSPCPSR_CPSDVSR)
	and t1, t1, t2
	li t2, (2)<<o_SSPCPSR_CPSDVSR 	# change this to prescale
	or t1, t1, t2
	sw t1, _SSPCPSR(t0)

	# set postdiv, clear first
	lw t1, _SSPCR0(t0)
	li t2, ~(m_SSPCR0_SCR)
	and t1, t1, t2
	li t2, (19-1)<<o_SSPCR0_SCR 	# change this to postdiv
	or t1, t1, t2
	sw t1, _SSPCR0(t0)

	li a0, 1
	call spi1_enable
	popra
	ret


# Initialize SPI1 as Master
.globl spi1_init
spi1_init:
	pushra
	# disable SPI
	li a0, 0
	call spi1_enable

	# set pins 10, 11, 12 to SPI
	li a0, 10 # SCLK
	li a1, 11 # MOSI
	li a2, 12 # MISO
	call spi_set_pins
	call spi1_reset

	# set mode and baudrate
	li a0, 8
	li a1, SPI_MODE0
	call spi1_set_format
	call spi1_set_baudrate
	# enable SPI
	li a0, 1
	call spi1_enable
	popra
	ret

# send and receive data
# a0 is *src, a1 is *dst, a2 is len
.equ FIFO_DEPTH, 8
.globl spi1_write_read
spi1_write_read:
	mv t2, a2 	# rx_remaining
	mv t3, a2 	# tx_remaining
	li t0, SPI1_BASE

	# if rx_remaining and tx_remaining are zero we are done
1:	bnez t2, 2f
	beqz t3, 3f

	# if (tx_remaining && spi_is_writable(spi) && rx_remaining < tx_remaining + fifo_depth)
2:	beqz t3, 4f
	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_TNF
	beqz t1, 4f
	addi t1, t3, FIFO_DEPTH
	bge t2, t1, 4f
	lb t1, 0(a0)
	sb t1, _SSPDR(t0)
	addi t3, t3, -1
	addi a0, a0, 1

	#if (rx_remaining && spi_is_readable(spi)) {
4:	beqz t2, 1b
	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_RNE
	beqz t1, 1b
	lb t1, _SSPDR(t0)
	sb t1, 0(a1)
	addi t2, t2, -1
	addi a1, a1, 1
	j 1b

	# return len
3:	mv a0, a2
	ret

# send data
# a0 is *src, a1 is len
.globl spi1_write
spi1_write:
	mv t2, a1 	# tx_remaining
	li t0, SPI1_BASE

	# if tx_remaining is zero we are done
1:	beqz t2, 3f
2:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_TNF
	beqz t1, 2b
	lb t1, 0(a0)
	sb t1, _SSPDR(t0)
	addi t2, t2, -1
	addi a0, a0, 1
	j 1b

    # Drain RX FIFO, then wait for shifting to finish (which may be *after*
    # TX FIFO drains), then drain RX FIFO again
spi1_drain_fifo:
3:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_RNE
	beqz t1, 4f
	lb t1, _SSPDR(t0)
	j 3b

4:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_BSY
	bnez t1, 4b

5:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_RNE
	beqz t1, 6f
	lb t1, _SSPDR(t0)
	j 5b

6:	li t1, b_SSPICR_RORIC
	sw t1, _SSPICR(t0)

	# return len
	mv a0, a1
	ret

# a0 has 16bit data to write, a1 has the number of 16bits to write
.globl spi1_write16n
spi1_write16n:
	mv t2, a1 	# tx_remaining
	li t0, SPI1_BASE
1:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_TNF
	beqz t1, 1b
	srli t1, a0, 8
	sb t1, _SSPDR(t0)	# upper byte
2:	lw t1, _SSPSR(t0)
	andi t1, t1, b_SSPSR_TNF
	beqz t1, 2b
	sb a0, _SSPDR(t0)	# lower byte
	addi t2, t2, -1
 	bnez t2, 1b
 	j spi1_drain_fifo

.globl test_spi
test_spi:
	pushra
	call spi1_init

	la a0, outbuf
	la a1, inbuf
	li a2, 5
	call spi1_write_read
	popra
	ret

.section .data
outbuf: .ascii "12345"
inbuf: .dcb.b 32
