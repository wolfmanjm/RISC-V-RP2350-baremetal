.section .text

.globl _start

_start:
	la sp, 0x20010000   # _stack_top   # Load stack pointer
	j _sysinit      	# Call sysinit

.section .text
# -----------------------------------------------------------------------------
.p2align 8 # This special signature must appear within the first 4 kb of
image_def: # the memory image to be recognised as a valid RISC-V binary.
# -----------------------------------------------------------------------------

.word 0xffffded3
.word 0x11010142
.word 0x00000344
.word _start
.word 0x20010000
.word 0x000004ff
.word 0x00000000
.word 0xab123579

.section .text

# clock setup taken from mecrisp-quintus by Mathias Koch
.equ RESETS_BASE, 0x40020000
.equ RESETS_PLL_USB, 15
.equ RESETS_PLL_SYS, 14
.equ RESETS_PLLS, (1<<RESETS_PLL_USB) | (1<<RESETS_PLL_SYS)

.equ XOSC_BASE, 0x40048000
.equ XOSC_CTRL,    XOSC_BASE + 0x00 # Crystal Oscillator Control
.equ XOSC_STATUS,  XOSC_BASE + 0x04 # Crystal Oscillator Status
.equ XOSC_DORMANT, XOSC_BASE + 0x08 # Crystal Oscillator pause control
.equ XOSC_STARTUP, XOSC_BASE + 0x0C # Controls the startup delay
.equ XOSC_COUNT,   XOSC_BASE + 0x10 # A down counter running at the XOSC frequency which counts to zero and stops.

.equ CLOCKS_BASE, 0x40010000
.equ _CLK_REF_CTRL, 0x30
.equ _CLK_REF_DIV, 0x34
.equ _CLK_REF_SELECTED, 0x38
.equ _CLK_SYS_CTRL, 0x3C
.equ _CLK_SYS_DIV, 0x40
.equ _CLK_SYS_SELECTED, 0x44
.equ _CLK_PERI_CTRL, 0x48
.equ _CLK_PERI_DIV, 0x4C

.equ _CLK_SYS_RESUS_CTRL, 0x84

.equ PLL_SYS_BASE, 0x40050000
.equ PLL_USB_BASE, 0x40058000
.equ PLL_CS, 0x0
.equ PLL_PWR, 0x4
.equ PLL_FBDIV_INT, 0x8
.equ PLL_PRIM, 0xc
.equ PLL_VCOPD, 5
.equ PLL_PD, 0
.equ PLL_POSTDIV1, 16
.equ PLL_POSTDIV2, 12
.equ PLL_CS_LOCK, 1 << 31
.equ PLL_START, (1<<PLL_VCOPD) | (1<<PLL_PD)
.equ PLL_SYS_DIV, (5<<PLL_POSTDIV1) | (2<<PLL_POSTDIV2)
.equ PLL_USB_DIV, (5<<PLL_POSTDIV1) | (4<<PLL_POSTDIV2)


.equ IO_BANK0_BASE, 0x40028000
.equ GPIO_0_STATUS,  IO_BANK0_BASE + (8 *  0)
.equ GPIO_0_CTRL,    IO_BANK0_BASE + (8 *  0) + 4
.equ GPIO_1_STATUS,  IO_BANK0_BASE + (8 *  1)
.equ GPIO_1_CTRL,    IO_BANK0_BASE + (8 *  1) + 4
.equ GPIO_25_STATUS, IO_BANK0_BASE + (8 * 25)
.equ GPIO_25_CTRL,   IO_BANK0_BASE + (8 * 25) + 4

.equ PADS_BANK0_BASE, 0x40038000
.equ GPIO_0_PAD,     PADS_BANK0_BASE + 0x04
.equ GPIO_1_PAD,     PADS_BANK0_BASE + 0x08
.equ GPIO_25_PAD,    PADS_BANK0_BASE + 0x68

.equ SIO_BASE, 0xd0000000
.equ GPIO_IN,        SIO_BASE + 0x004  # Input value for GPIO pins
.equ GPIO_OUT,       SIO_BASE + 0x010  # GPIO output value
.equ GPIO_OE,        SIO_BASE + 0x030  # GPIO output enable

.equ UART0_BASE, 0x40070000
.equ UART0_DR   , UART0_BASE + 0x00 # Data Register, UARTDR
.equ UART0_RSR  , UART0_BASE + 0x04 # Receive Status Register/Error Clear Register, UARTRSR/UARTECR
.equ UART0_FR   , UART0_BASE + 0x18 # Flag Register, UARTFR
.equ UART0_ILPR , UART0_BASE + 0x20 # IrDA Low-Power Counter Register, UARTILPR
.equ UART0_IBRD , UART0_BASE + 0x24 # Integer Baud Rate Register, UARTIBRD
.equ UART0_FBRD , UART0_BASE + 0x28 # Fractional Baud Rate Register, UARTFBRD
.equ UART0_LCR_H, UART0_BASE + 0x2c # Line Control Register, UARTLCR_H
.equ UART0_CR   , UART0_BASE + 0x30 # Control Register, UARTCR
.equ UART0_IFLS , UART0_BASE + 0x34 # Interrupt FIFO Level Select Register, UARTIFLS
.equ UART0_IMSC , UART0_BASE + 0x38 # Interrupt Mask Set/Clear Register, UARTIMSC
.equ UART0_RIS  , UART0_BASE + 0x3c # Raw Interrupt Status Register, UARTRIS
.equ UART0_MIS  , UART0_BASE + 0x40 # Masked Interrupt Status Register, UARTMIS
.equ UART0_ICR  , UART0_BASE + 0x44 # Interrupt Clear Register, UARTICR
.equ UART0_DMACR, UART0_BASE + 0x48 # DMA Control Register, UARTDMACR

#  Define Atomic Register Access
#   See section 2.1.3 "Atomic Register Access" in RP2350 datasheet

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

_sysinit:
	# Start cycle counter
	csrrwi zero, 0x320, 4  # MCOUNTINHIBIT: Keep minstret(h) stopped, but run mcycle(h).

	# Remove reset of all subsystems
	li t1, RESETS_BASE
	sw zero, 0(t1)

	# Disable Resus
	li t1, CLOCKS_BASE
	sw zero, _CLK_SYS_RESUS_CTRL(t1)

	# Configure XOSC to use 12 MHz crystal
	li t1, XOSC_CTRL      #  XOSC range 1-15MHz (Crystal Oscillator)
	li t2, 0x00000aa0
	sw t2, 0(t1)

	li t1, XOSC_STARTUP   # Startup Delay (default = 50,000 cycles aprox.)
	li t2, 0x0000011c
	sw t2, 0(t1)

	li t1, XOSC_CTRL | WRITE_SET   # Enable XOSC
	li t2, 0x00FAB000
	sw t2, 0(t1)

	li t1, XOSC_STATUS    # Wait for XOSC being stable
1:	lw t2, 0(t1)
	srli t2, t2, 31
	beqz t2, 1b

	# Before we touch PLLs, switch sys and ref cleanly away from their aux sources.
		# hw_clear_bits(&clocks_hw->clk[clk_sys].ctrl, CLOCKS_CLK_SYS_CTRL_SRC_BITS:1);
	li t1, CLOCKS_BASE | WRITE_CLR
	li t0, 1
	sw t0, _CLK_SYS_CTRL(t1)
		# while (clocks_hw->clk[clk_sys].selected != 0x1)
	li t1, CLOCKS_BASE
1:	lw t2, _CLK_SYS_SELECTED(t1)
	bne t0, t2, 1b
		# hw_clear_bits(&clocks_hw->clk[clk_ref].ctrl, CLOCKS_CLK_REF_CTRL_SRC_BITS:3);
	li t1, CLOCKS_BASE | WRITE_CLR
	li t0, 3
	sw t0, _CLK_REF_CTRL(t1)
		# while (clocks_hw->clk[clk_ref].selected != 0x1)
	li t1, CLOCKS_BASE
	li t0, 1
1:	lw t2, _CLK_REF_SELECTED(t1)
	bne t0, t2, 1b

	#	Reset PLLs
	li t1, RESETS_BASE | WRITE_SET
	li t0, RESETS_PLLS
	sw t0, 0(t1)
	li t1, RESETS_BASE | WRITE_CLR
	sw t0, 0(t1)
	li t1, RESETS_BASE
1:	lw t2, 8(t1) # RESETS_DONE
	and t2, t2, t0
	bne t2, t0, 1b

	# setup PLL for 150MHz from the XOSC

	# Don't divide the crystal frequency
	li t2, PLL_SYS_BASE
	li t3, PLL_USB_BASE
	li t0, 1
	sw t0, PLL_CS(t2)
	sw t0, PLL_CS(t3)

	# SYS: VCO = 12MHz * 125 = 1500MHz
	# USB: VCO = 12MHz *  80 =  960MHz
	li t0, 125
	sw t0, PLL_FBDIV_INT(t2)
	li t0, 80
	sw t0, PLL_FBDIV_INT(t3)

	# Start PLLs
	li t2, PLL_SYS_BASE | WRITE_CLR
	li t3, PLL_USB_BASE | WRITE_CLR
	li t0, PLL_START
	sw t0, PLL_PWR(t2)
	sw t0, PLL_PWR(t3)

	# Wait until both PLLs are locked
	li t2, PLL_SYS_BASE
	li t3, PLL_USB_BASE
	li t4, 0x80000000
1:	lw t0, PLL_CS(t2)
	lw t1, PLL_CS(t3)
	and t0, t0, t1
	and t0, t0, t4
	bne t0, t4, 1b

	# Set the PLL post dividers
	li t0, PLL_SYS_DIV
	li t1, PLL_USB_DIV
	sw t0, PLL_PRIM(t2)
	sw t1, PLL_PRIM(t3)
	li t2, PLL_SYS_BASE | WRITE_CLR
	li t3, PLL_USB_BASE | WRITE_CLR
	li t0, 8
	sw t0, PLL_PWR(t2)
	sw t0, PLL_PWR(t3)

	# setup clk_ref
	li t1, CLOCKS_BASE
	lw t2, _CLK_REF_CTRL(t1)
	# xori t2, t2, 0
	andi t2, t2, 0xE0
	li t1, CLOCKS_BASE | WRITE_XOR
	sw t2, _CLK_REF_CTRL(t1)

	li t1, CLOCKS_BASE
	lw t2, _CLK_REF_CTRL(t1)
	xori t2, t2, 2
	andi t2, t2, 0x03
	li t1, CLOCKS_BASE | WRITE_XOR
	sw t2, _CLK_REF_CTRL(t1)

	li t1, CLOCKS_BASE
1:	lw t2, _CLK_REF_SELECTED(t1)
	andi t2, t2, 1<<2
	beqz t2, 1b

	# Does nothing on ref clk
	# li t1, CLOCKS_BASE | WRITE_SET
	# li t2, 0x0800
	# sw t2, _CLK_REF_CTRL(t1)

	li t1, CLOCKS_BASE
	li t2, 1<<16
	sw t2, _CLK_REF_DIV(t1)


	# setup sys clk to 150MHz
	li t1, CLOCKS_BASE | WRITE_CLR
	li t2, 0x03
	sw t2, _CLK_SYS_CTRL(t1)
	li t1, CLOCKS_BASE
1:	lw t2, _CLK_SYS_SELECTED(t1)
	andi t2, t2, 1
	beqz t2, 1b

	li t1, CLOCKS_BASE
	lw t2, _CLK_SYS_CTRL(t1)
	# xori t2, t2, 0
	andi t2, t2, 0xE0
	li t1, CLOCKS_BASE | WRITE_XOR
	sw t2, _CLK_SYS_CTRL(t1)

	li t1, CLOCKS_BASE
	lw t2, _CLK_SYS_CTRL(t1)
	xori t2, t2, 1
	andi t2, t2, 0x03
	li t1, CLOCKS_BASE | WRITE_XOR
	sw t2, _CLK_SYS_CTRL(t1)

	li t1, CLOCKS_BASE
1:	lw t2, _CLK_SYS_SELECTED(t1)
	andi t2, t2, 1<<1
	beqz t2, 1b

	li t1, CLOCKS_BASE
	li t2, 1<<16
	sw t2, _CLK_SYS_DIV(t1)


	# Enable peripheral clock
	li t1, CLOCKS_BASE | WRITE_SET
	li t0, 0x800
	sw t0, _CLK_PERI_CTRL(t1)
	li t1, CLOCKS_BASE
	li t2, 1<<16
	sw t2, _CLK_PERI_DIV(t1)

	call main
	wfi                 # Wait for interrupt (to save power)

2:  j 2b

.globl main
main:
	# call setup_uart
	# call spi1_init
	# call toggle_pin
	call test_uart

	wfi                 # Wait for interrupt (to save power)
2:  j 2b
