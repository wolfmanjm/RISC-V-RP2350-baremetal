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

.equ XOSC_BASE, 0x40048000
.equ XOSC_CTRL,    XOSC_BASE + 0x00 # Crystal Oscillator Control
.equ XOSC_STATUS,  XOSC_BASE + 0x04 # Crystal Oscillator Status
.equ XOSC_DORMANT, XOSC_BASE + 0x08 # Crystal Oscillator pause control
.equ XOSC_STARTUP, XOSC_BASE + 0x0C # Controls the startup delay
.equ XOSC_COUNT,   XOSC_BASE + 0x10 # A down counter running at the XOSC frequency which counts to zero and stops.

.equ CLOCKS_BASE, 0x40010000
.equ CLK_SYS_CTRL,   CLOCKS_BASE + 0x3C
.equ CLK_PERI_CTRL,  CLOCKS_BASE + 0x48

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
	li x15, RESETS_BASE
	sw zero, 0(x15)

	# Configure XOSC to use 12 MHz crystal

	li x15, XOSC_CTRL      #  XOSC range 1-15MHz (Crystal Oscillator)
	li x14, 0x00000aa0
	sw x14, 0(x15)

	li x15, XOSC_STARTUP   # Startup Delay (default = 50,000 cycles aprox.)
	li x14, 0x0000011c
	sw x14, 0(x15)

	li x15, XOSC_CTRL | WRITE_SET   # Enable XOSC
	li x14, 0x00FAB000
	sw x14, 0(x15)

	li x15, XOSC_STATUS    # Wait for XOSC being stable
1:	lw x14, 0(x15)
	srli x14, x14, 31
	beqz x14, 1b

	# setup PLL for 150MHz from the XOSC
	# TODO

	# Select main clock
	li x15, CLK_SYS_CTRL
	li x14, (3 << 5)
	sw x14, 0(x15)

	# Enable peripheral clock
	li x15, CLK_PERI_CTRL
	li x14, 0x800 | (4 << 5)   # Enabled, XOSC as source
	sw x14, 0(x15)

	call main
	wfi                 # Wait for interrupt (to save power)

2:  j 2b
