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

	.equ  IO_BANK0_BASE, 0x40028000
	.equ  _GPIO_STATUS, 0x00  		# pin# * 8
	.equ  _GPIO_CTRL, 0x04

	.equ  PADS_BANK0_BASE, 0x40038000

	.equ  RESETS_RESET, 0x40020000

	.equ GPIO_FUNC_SPI, 1 

	# cpol cpha
	.equ  SPI_MODE0, 0x00 
	.equ  SPI_MODE1, 0x01 
	.equ  SPI_MODE2, 0x10 
	.equ  SPI_MODE3, 0x11 

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
	li t1, RESETS_RESET
	li t0, 1<<19		# set reset
	sw t0, 0(t1)
	sw zero, 0(t1)
1:	lw t2, 8(t1)		# RESETS_RESET_DONE
	and t2, t2, t0		# begin 1<<19 RESETS_RESET_DONE bit@ until
	beqz t2, 1b
	ret

# set pins in a0, a1, a2 as SCLK, MOSI, MISO, to SPI function
spi_set_pins:
	li t1, IO_BANK0_BASE
	li t4, GPIO_FUNC_SPI
	sh3add t2, a0, t1 		# get the offet for the pin (pin# * 8)
	sw t4, _GPIO_CTRL(t2) 	# set to SPI function
	sh3add t2, a1, t1 		# get the offet for the pin (pin# * 8)
	sw t4, _GPIO_CTRL(t2) 	# set to SPI function
	sh3add t2, a2, t1 		# get the offet for the pin (pin# * 8)
	sw t4, _GPIO_CTRL(t2) 	# set to SPI function

    # Remove pad isolation control bits
	li t1, PADS_BANK0_BASE
	sh2add t2, a0, t1 		# get the offet for the pin (pin# * 4 + 4)
	sw zero, 4(t2)
	sh2add t2, a1, t1
	sw zero, 4(t2)
	sh2add t2, a2, t1
	sw zero, 4(t2)
	# set input enable on MISO
	bseti t0, zero, 6  		# 1<<6
	sw t0, 4(t2)
	ret

spi1_enable:
	li t1, SPI1_BASE
	lw t0, _SSPCR1(t1)
    beqz a0, 1f				# $02 SPI1_SSPCR1 rot if bis! else bic! then
	bseti t0, t0, 1
	j 2f
1:	bclri t0, t0, 1
2:  sw t0, _SSPCR1(t1)
	ret

# set SPI format a0 - #bits, a1 - mode
spi1_set_format:
	pushra
	li a0, 0
	jal spi1_enable

	addi t0, a0, -1
	andi t0, t0, 0xFF
	andi t1, a1, 0x03
	slli t1, t1, 6
	or  t0, t0, t1
	li t2, SPI1_BASE
	lw t3, _SSPCR0(t2)
	andi t3, t3, ~0b11001111  	# clear bits
	or t3, t3, t0 				# set new bits
	sw t3, _SSPCR0(t2)  		# set bits

	li a0, 1
	jal spi1_enable
	popra
	ret

# Initialize SPI1 as Master
spi1_init:
	pushra
	li a0, 0
	jal spi1_enable

	# set pins 10, 11, 12 to SPI
	li a0, 10 # SCLK
	li a1, 11 # MOSI
	li a2, 12 # MISO
	jal spi_set_pins

	jal	spi1_reset

	li a0, 8
	li a1, SPI_MODE0
	jal spi1_set_format
	# set baudrate
	# TODO
	# enable SPI
	li a0, 1
	jal spi1_enable
	popra
	ret

.globl main
main:
	# call setup_uart
	# call spi1_init
	call toggle_pin
	ret
