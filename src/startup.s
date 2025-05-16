.equ STACK_TOP, 0x20080000 - 0x0100

.equ RVCSR_MEIEA_OFFSET, 0x00000be0
.equ RVCSR_MEIFA_OFFSET, 0x00000be2
.equ RVCSR_MIE_MEIE_BITS,  0x00000800
.equ RVCSR_MSTATUS_MIE_BITS,  0x00000008

.globl _start
.section .text
_start:
.option push
.option norelax
    la gp, 0
.option pop
    la sp, STACK_TOP
    la a0, __vectors + 1
    csrw mtvec, a0

    # Only core 0 should run at this time; core 1 is normally
    # sleeping in the bootrom at this point but check to be sure
    csrr a0, mhartid
    bnez a0, reenter_bootrom

    # clear the .bss section
    la a1, _sbss
    la a2, _ebss
    j bss_fill_test
bss_fill_loop:
    sw zero, (a1)
    addi a1, a1, 4
bss_fill_test:
    bltu a1, a2, bss_fill_loop

    # copy .data into RAM, only happens if _sidata is different to _sdata
copy_data_section:
    la a1, _sidata  # where in Flash it is
    la a2, _sdata 	# where it needs to be copied to
    la a3, _edata 	# upto here
    beq a1, a2, 3f	# if equal no need to copy anything
    j 2f
1:  lw a0, (a1)
    sw a0, (a2)
    addi a1, a1, 4
    addi a2, a2, 4
2:  bltu a2, a3, 1b

3: 	# jumps here if everything is in RAM

    # some init taken from crt0
    # clear all IRQ force array bits. Iterate over array registers 0
    # through 3 inclusive, allowing for up to 64 IRQs. Also clear the
    # enable array.
    li a0, 3
1:  csrw RVCSR_MEIFA_OFFSET, a0
    csrw RVCSR_MEIEA_OFFSET, a0
    addi a0, a0, -1
    bgez a0, 1b
    # Setting the global external IRQ enable in mie prepares us to enable
    # IRQs one-by-one later. Also clear the soft IRQ and timer IRQ enables:
    li a0, RVCSR_MIE_MEIE_BITS
    csrw mie, a0
    # Set the global IRQ: we will now take any individual interrupt that is
    # pending && enabled
    csrsi mstatus, RVCSR_MSTATUS_MIE_BITS
    # Take this chance to clear mscratch, which is used to detect nested
    # exceptions in isr_riscv_machine_exception:
    csrw mscratch, zero

	j _sysinit      # Call sysinit

.equ BOOTROM_ENTRY_OFFSET, 0x7dfc
reenter_bootrom:
    li a0, BOOTROM_ENTRY_OFFSET + 32 * 1024
    la a1, 1f
    csrw mtvec, a1
    jr a0
    # Go here if we trapped:
.p2align 2
1:  li a0, BOOTROM_ENTRY_OFFSET
    jr a0

# goes in .data section
.section .time_critical
.p2align 2

# default handlers so we can see what the exception was
isr_riscv_machine_exception:
	csrr ra, mepc
	csrr t6, mcause
	ebreak
1: j 1b

isr_riscv_machine_soft_irq:
1: j 1b

isr_riscv_machine_timer:
1: j 1b


.equ RVCSR_MEINEXT_OFFSET, 0x00000be4
.equ RVCSR_MEINEXT_BITS,   0x800007fd
.equ RVCSR_MEINEXT_RESET,  0x00000000
.equ RVCSR_MEINEXT_UPDATE_BITS, 0x00000001

isr_riscv_machine_external_irq:
    addi sp, sp, -12
    sw ra,  0(sp)
    sw t0,  4(sp)
    sw t1,  8(sp)

    # figure out which interrupt
    csrr t1, RVCSR_MEINEXT_OFFSET
    # MSB will be set if there is no active IRQ at the current priority level
    bltz t1, no_more_irqs
dispatch_irq:
	# Load indexed table entry and jump through it.
	lui t0, %hi(__soft_vector_table)
	add t0, t0, t1
	lw t0, %lo(__soft_vector_table)(t0)
	jalr ra, t0
get_next_irq:
	# Get the next-highest-priority IRQ
	csrr t1, RVCSR_MEINEXT_OFFSET
	# MSB will be set if there is no active IRQ at the current priority level
	bgez t1, dispatch_irq

no_more_irqs:
    lw ra,  0(sp)
    lw t0,  4(sp)
    lw t1,  8(sp)
	addi sp, sp, 12
	mret

.section .text

.globl enable_irq
# enable/disable (a1=1|0) the irq specified in a0
enable_irq:
		# irq_set_mask_n_enabled(num / 32, 1u << (num % 32), enabled);
        # hazard3_irqarray_clear(RVCSR_MEIFA_OFFSET, 2 * n, mask & 0xffffu);
        # hazard3_irqarray_clear(RVCSR_MEIFA_OFFSET, 2 * n + 1, mask >> 16);
        # hazard3_irqarray_set(RVCSR_MEIEA_OFFSET, 2 * n, mask & 0xffffu);
        # hazard3_irqarray_set(RVCSR_MEIEA_OFFSET, 2 * n + 1, mask >> 16);
    srli t0, a0, 5  		# n
    slli t0, t0, 1			# 2*n
    andi t1, a0, 31 	# mask
    bset t1, zero, t1 	# bitset
	slli t2, t1, 16				# upper 16 bits are bit to set (mask),
	or t2, t2, t0 				# lower 5 bits are the window (n)
    beqz a1, 1f
	csrc RVCSR_MEIFA_OFFSET, t2
	csrs RVCSR_MEIEA_OFFSET, t2 # enable
	j 2f
1:	csrc RVCSR_MEIEA_OFFSET, t2 # disable
2:	srli t2, t1, 16
	addi t0, t0, 1
	slli t2, t2, 16				# upper 16 bits are bit to set (mask),
	or t2, t2, t0 				# lower 5 bits are the window (n)
    beqz a1, 1f
	csrc RVCSR_MEIFA_OFFSET, t2
	csrs RVCSR_MEIEA_OFFSET, t2
	j 2f
1: 	csrc RVCSR_MEIEA_OFFSET, t2
2:	ret

# a0 has the vector to set and a1 has the callback address
.globl set_irq_vector
set_irq_vector:
	la t0, __soft_vector_table
	sh2add t0, a0, t0
	sw a1, 0(t0)
	ret

unhandled_ext_irq:
1: j 1b

.section .data
.p2align 6
.globl __vectors, __VECTOR_TABLE
__VECTOR_TABLE:
__vectors:
# Hardware vector table for standard RISC-V interrupts, indicated by `mtvec`.
.option push
.option norvc
.option norelax
j isr_riscv_machine_exception
.word 0
.word 0
j isr_riscv_machine_soft_irq
.word 0
.word 0
.word 0
j isr_riscv_machine_timer
.word 0
.word 0
.word 0
j isr_riscv_machine_external_irq
.option pop

.p2align 4
.globl __soft_vector_table
__soft_vector_table:
.word unhandled_ext_irq # isr_irq0
.word unhandled_ext_irq # isr_irq1
.word unhandled_ext_irq # isr_irq2
.word unhandled_ext_irq # isr_irq3
.word unhandled_ext_irq # isr_irq4
.word unhandled_ext_irq # isr_irq5
.word unhandled_ext_irq # isr_irq6
.word unhandled_ext_irq # isr_irq7
.word unhandled_ext_irq # isr_irq8
.word unhandled_ext_irq # isr_irq9
.word unhandled_ext_irq # isr_irq10
.word unhandled_ext_irq # isr_irq11
.word unhandled_ext_irq # isr_irq12
.word unhandled_ext_irq # isr_irq13
.word unhandled_ext_irq # isr_irq14
.word unhandled_ext_irq # isr_irq15
.word unhandled_ext_irq # isr_irq16
.word unhandled_ext_irq # isr_irq17
.word unhandled_ext_irq # isr_irq18
.word unhandled_ext_irq # isr_irq19
.word unhandled_ext_irq # isr_irq20
.word unhandled_ext_irq # isr_irq21
.word unhandled_ext_irq # isr_irq22
.word unhandled_ext_irq # isr_irq23
.word unhandled_ext_irq # isr_irq24
.word unhandled_ext_irq # isr_irq25
.word unhandled_ext_irq # isr_irq26
.word unhandled_ext_irq # isr_irq27
.word unhandled_ext_irq # isr_irq28
.word unhandled_ext_irq # isr_irq29
.word unhandled_ext_irq # isr_irq30
.word unhandled_ext_irq # isr_irq31
.word unhandled_ext_irq # isr_irq32
.word unhandled_ext_irq # isr_irq33
.word unhandled_ext_irq # isr_irq34
.word unhandled_ext_irq # isr_irq35
.word unhandled_ext_irq # isr_irq36
.word unhandled_ext_irq # isr_irq37
.word unhandled_ext_irq # isr_irq38
.word unhandled_ext_irq # isr_irq39
.word unhandled_ext_irq # isr_irq40
.word unhandled_ext_irq # isr_irq41
.word unhandled_ext_irq # isr_irq42
.word unhandled_ext_irq # isr_irq43
.word unhandled_ext_irq # isr_irq44
.word unhandled_ext_irq # isr_irq45
.word unhandled_ext_irq # isr_irq46
.word unhandled_ext_irq # isr_irq47
.word unhandled_ext_irq # isr_irq48
.word unhandled_ext_irq # isr_irq49
.word unhandled_ext_irq # isr_irq50
.word unhandled_ext_irq # isr_irq51

.section .text
# -----------------------------------------------------------------------------
.p2align 2 # This special signature must appear within the first 4 kb of
image_def: # the memory image to be recognised as a valid RISC-V binary.
# -----------------------------------------------------------------------------

.word 0xffffded3
.word 0x11010142
.word 0x00000344
.word _start
.word STACK_TOP
.word 0x000004ff
.word 0x00000000
.word 0xab123579

.section .text

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

.equ TICKS_BASE, 0x40108000
.equ _TICKS_CTRL, 0x00
.equ _TICKS_CYCLES, 0x04
.equ _TICKS_COUNT, 0x08

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

	# setup the ticks based on clocks
	call setup_ticks

	call main
	wfi                 # Wait for interrupt (to save power)

2:  j 2b
