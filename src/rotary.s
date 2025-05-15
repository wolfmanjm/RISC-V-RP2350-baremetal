# based on the arduino library rotary

.equ R_START, 0x0
.equ R_CW_FINAL, 0x1
.equ R_CW_BEGIN, 0x2
.equ R_CW_NEXT, 0x3
.equ R_CCW_BEGIN, 0x4
.equ R_CCW_FINAL, 0x5
.equ R_CCW_NEXT, 0x6
.equ DIR_NONE, 0x0
.equ DIR_CW, 0x10
.equ DIR_CCW, 0x20

.equ CELL, 4
.macro pushra
  	addi sp, sp, -CELL
  	sw ra, 0(sp)
.endm
.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, CELL
.endm

.include "interrupt_vectors.s"

.section .data
.p2align 2
rotary_count: .word 0
rotary_state: .byte 0
enc_pins: .byte 0, 0

.section .rodata
.p2align 2
rotary_ttable: # [7][4]
    # R_START
    .byte R_START,    R_CW_BEGIN,  R_CCW_BEGIN, R_START
    # R_CW_FINAL
    .byte R_CW_NEXT,  R_START,     R_CW_FINAL,  R_START | DIR_CW
    # R_CW_BEGIN
    .byte R_CW_NEXT,  R_CW_BEGIN,  R_START,     R_START
    # R_CW_NEXT
    .byte R_CW_NEXT,  R_CW_BEGIN,  R_CW_FINAL,  R_START
    # R_CCW_BEGIN
    .byte R_CCW_NEXT, R_START,     R_CCW_BEGIN, R_START
    # R_CCW_FINAL
    .byte R_CCW_NEXT, R_CCW_FINAL, R_START,     R_START | DIR_CCW
    # R_CCW_NEXT
    .byte R_CCW_NEXT, R_CCW_FINAL, R_CCW_BEGIN, R_START

.section .text
process:
	pushra
	li t1, 0
	la t0, enc_pins
	lb a0, 0(t0)
	call pin_get
	beqz a0, 1f
	bseti t1, t1, 1 	# pinstate
1:	la t0, enc_pins
	lb a0, 1(t0)
	call pin_get
	beqz a0, 2f
	bseti t1, t1, 0 	# pinstate
2:	la t0, rotary_ttable
	la t2, rotary_state
	lb t2, 0(t2)
	andi t2, t2, 0x0F 	# state&0x0F
	sh2add t2, t2, t0 	# rotary_ttable[state & 0xf][0]
	add t2, t2, t1 		# rotary_ttable[state & 0xf][pinstate]
	lb t0, 0(t2)		# state = rotary_ttable[state & 0xf][pinstate]
	la t2, rotary_state
	sb t0, 0(t2)
	andi a0, t0, 0x30
	popra
	ret

handle_enc_irq:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw a0, 4(sp)
  	sw t0, 8(sp)
  	sw t1, 12(sp)
  	sw t2, 16(sp)

	call process
	li t0, DIR_CW
	bne a0, t0, 1f
	la t0, rotary_count	# ++rotary_count
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j 2f
1:	li t0, DIR_CCW
	bne a0, t0, 2f
	la t0, rotary_count
	lw t1, 0(t0)
	addi t1, t1, -1
	sw t1, 0(t0)	# --rotary_count

2: 	lw ra, 0(sp)
  	lw a0, 4(sp)
  	lw t0, 8(sp)
  	lw t1, 12(sp)
  	lw t2, 16(sp)
  	addi sp, sp, 20
	ret

# a0 has enca pin, a1 has encb pin
.globl rotary_init
rotary_init:
	pushra
	la t0, rotary_state
	li t1, R_START
    sb t1, 0(t0)
    la t0, rotary_count
    sw zero, 0(t0)
   	la t0, enc_pins
	sb a0, 0(t0)
	sb a1, 1(t0)

	call pin_input_pu
	mv a0, a1
	call pin_input_pu

	call gpio_disable_common_irq

   	la t0, enc_pins
	lb a0, 0(t0)
	la a1, handle_enc_irq
	li a2, b_INTR_EDGE_HIGH|b_INTR_EDGE_LOW
	call gpio_enable_interrupt
   	la t0, enc_pins
	lb a0, 1(t0)
	la a1, handle_enc_irq
	li a2, b_INTR_EDGE_HIGH|b_INTR_EDGE_LOW
	call gpio_enable_interrupt

	call gpio_enable_common_irq

    popra
    ret

.globl rotary_get_count
rotary_get_count:
	la t0, rotary_count
	lw a0, 0(t0)
	ret

.globl test_rotary
test_rotary:
	pushra
	li a0, 14
	li a1, 15
	call rotary_init

	call uart_init       # Initialize UART
    la a0, msg           # Load address of message
    call uart_puts       # Print message

1:	wfi
	la t0, rotary_count
    lw a0, 0(t0)
    la t1, lstcnt 		# if changed then print
    lw t2, 0(t1)
    beq a0, t2, 1b
    sw a0, 0(t1) 		# update lstcnt
    la a1, numstr
    call parse_n
    la a0, numstr
    call uart_puts
    li a0, 10
    call uart_putc
    j 1b

	popra
	ret

.section .data
.p2align 2
lstcnt: .word 0
numstr: .dcb.b 32
msg: .asciz "Rotary Encoder test on pins 14, 15\n"

