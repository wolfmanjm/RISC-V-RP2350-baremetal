.equ CELL, 4
.macro pushra
  	addi sp, sp, -CELL
  	sw ra, 0(sp)
.endm
.macro popra
  	lw ra, 0(sp)
  	addi sp, sp, CELL
.endm

# pins used
.equ RST_PIN, 7
.equ DC_PIN, 8
.equ CS_PIN, 9
.equ SCLK_PIN, 10
.equ MOSI_PIN, 11
.equ MISO_PIN, 12

# commands
.equ  NOP, 0x00                   # No-op
.equ  SWRESET, 0x01               # Software reset
.equ  RDDID, 0x04                 # Read display ID info
.equ  RDDST, 0x09                 # Read display status
.equ  SLPIN, 0x10                 # Enter sleep mode
.equ  SLPOUT, 0x11                # Exit sleep mode
.equ  PTLON, 0x12                 # Partial mode on
.equ  NORON, 0x13                 # Normal display mode on
.equ  RDMODE, 0x0A                # Read display power mode
.equ  RDMADCTL, 0x0B              # Read display MADCTL
.equ  RDPIXFMT, 0x0C              # Read display pixel format
.equ  RDIMGFMT, 0x0D              # Read display image format
.equ  RDSELFDIAG, 0x0F            # Read display self-diagnostic
.equ  INVOFF, 0x20                # Display inversion off
.equ  INVON, 0x21                 # Display inversion on
.equ  GAMMASET, 0x26              # Gamma set
.equ  DISPLAY_OFF, 0x28           # Display off
.equ  DISPLAY_ON, 0x29            # Display on
.equ  SET_COLUMN, 0x2A            # Column address set
.equ  SET_PAGE, 0x2B              # Page address set
.equ  WRITE_RAM, 0x2C             # Memory write
.equ  READ_RAM, 0x2E              # Memory read
.equ  PTLAR, 0x30                 # Partial area
.equ  VSCRDEF, 0x33               # Vertical scrolling definition
.equ  MADCTL, 0x36                # Memory access control
.equ  VSCRSADD, 0x37              # Vertical scrolling start address
.equ  PIXFMT, 0x3A                # COLMOD: Pixel format set
.equ  WRITE_DISPLAY_BRIGHTNESS, 0x51                 # Brightness hardware dependent!
.equ  READ_DISPLAY_BRIGHTNESS, 0x52
.equ  WRITE_CTRL_DISPLAY, 0x53
.equ  READ_CTRL_DISPLAY, 0x54
.equ  WRITE_CABC, 0x55               # Write Content Adaptive Brightness Control
.equ  READ_CABC, 0x56                # Read Content Adaptive Brightness Control
.equ  WRITE_CABC_MINIMUM, 0x5E       # Write CABC Minimum Brightness
.equ  READ_CABC_MINIMUM, 0x5F        # Read CABC Minimum Brightness
.equ  FRMCTR1, 0xB1                  # Frame rate control (In normal mode/full colors)
.equ  FRMCTR2, 0xB2                  # Frame rate control (In idle mode/8 colors)
.equ  FRMCTR3, 0xB3                  # Frame rate control (In partial mode/full colors)
.equ  INVCTR, 0xB4                   # Display inversion control
.equ  DFUNCTR, 0xB6                  # Display function control
.equ  PWCTR1, 0xC0                   # Power control 1
.equ  PWCTR2, 0xC1                   # Power control 2
.equ  PWCTRA, 0xCB                   # Power control A
.equ  PWCTRB, 0xCF                   # Power control B
.equ  VMCTR1, 0xC5                   # VCOM control 1
.equ  VMCTR2, 0xC7                   # VCOM control 2
.equ  RDID1, 0xDA                    # Read ID 1
.equ  RDID2, 0xDB                    # Read ID 2
.equ  RDID3, 0xDC                    # Read ID 3
.equ  RDID4, 0xDD                    # Read ID 4
.equ  GMCTRP1, 0xE0                  # Positive gamma correction
.equ  GMCTRN1, 0xE1                  # Negative gamma correction
.equ  DTCA, 0xE8                     # Driver timing control A
.equ  DTCB, 0xEA                     # Driver timing control B
.equ  POSC, 0xED                     # Power on sequence control
.equ  ENABLE3G, 0xF2                 # Enable 3 gamma control
.equ  PUMPRC, 0xF7                   # Pump ratio control

.equ defWIDTH, 240
.equ defHEIGHT, 320
.equ ILI9341_WIDTH, defWIDTH
.equ ILI9341_HEIGHT, defHEIGHT
.equ ILI9341_SCREEN_SIZE, ILI9341_WIDTH * ILI9341_HEIGHT

.section .rodata
# columns: 1 = # of params, 2 = command, 3 .. = params
INIT_CMD:
 .byte  4, 0xEF, 0x03, 0x80, 0x02
 .byte  4, PWCTRB   , 0x00, 0xC1, 0x30               # Pwr ctrl B
 .byte  5, POSC     , 0x64, 0x03, 0x12, 0x81         # Pwr on seq. ctrl
 .byte  4, DTCA     , 0x85, 0x00, 0x78               # Driver timing ctrl A
 .byte  6, PWCTRA   , 0x39, 0x2C, 0x00, 0x34, 0x02   # Pwr ctrl A
 .byte  2, PUMPRC   , 0x20                           # Pump ratio control
 .byte  3, DTCB     , 0x00, 0x00                     # Driver timing ctrl B
 .byte  2, PWCTR1   , 0x23                           # Pwr ctrl 1
 .byte  2, PWCTR2   , 0x10                           # Pwr ctrl 2
 .byte  3, VMCTR1   , 0x3E, 0x28                     # VCOM ctrl 1
 .byte  2, VMCTR2   , 0x86                           # VCOM ctrl 2
 .byte  2, MADCTL   , 0x88                           # Memory access ctrl
 .byte  2, PIXFMT   , 0x55                           # COLMOD: Pixel format
 .byte  4, DFUNCTR  , 0x08, 0x82, 0x27
 .byte  2, ENABLE3G , 0x00                           # Enable 3 gamma ctrl
 .byte  2, GAMMASET , 0x01                           # Gamma curve selected
 .byte 16, GMCTRP1  , 0x0F, 0x31, 0x2B, 0x0C, 0x0E
 .byte     0x08, 0x4E, 0xF1, 0x37, 0x07
 .byte     0x10, 0x03, 0x0E, 0x09, 0x00
 .byte 16, GMCTRN1  , 0x00, 0x0E, 0x14, 0x03, 0x11
 .byte     0x07, 0x31, 0xC1, 0x48, 0x08
 .byte     0x0F, 0x0C, 0x31, 0x36, 0x0F
 .byte  3, FRMCTR1  , 0x00, 0x10                     # Frame rate ctrl
 .byte  0,  0  										 # terminate list

.section .data
.p2align 2
spi_data: .dcb.b 4
fg_color: .word 0xFFFF
bg_color: .word 0

.section .text
dc_low:
	pushra
	li a0, DC_PIN
	call pin_low
	popra
	ret
dc_high:
	pushra
	li a0, DC_PIN
	call pin_high
	popra
	ret
cs_low:
	pushra
	li a0, CS_PIN
	call pin_low
	popra
	ret
cs_high:
	pushra
	li a0, CS_PIN
	call pin_high
	popra
	ret
rst_low:
	pushra
	li a0, RST_PIN
	call pin_low
	popra
	ret
rst_high:
	pushra
	li a0, RST_PIN
	call pin_high
	popra
	ret

write_cmd:
	pushra
	la t0, spi_data
	sb a0, 0(t0)
    call dc_low
    call cs_low
	la a0, spi_data
	li a1, 1
	call spi1_write
	call cs_high
	popra
	ret

write_data:
	pushra
	mv t4, a0
    call dc_high
    call cs_low

	mv a0, t4
	call spi1_write

    call cs_high
	popra
	ret

write_data16n:
	pushra
	mv t4, a0
    call dc_high
    call cs_low
	mv a0, t4
	call spi1_write16n
    call cs_high
	popra
	ret

init_commands:
  	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s0, 4(sp)
  	sw s1, 8(sp)

    li a0, SWRESET
    call write_cmd        # software reset
    li a0, 100
    call delayms
    la s0, INIT_CMD
1:  lb s1, 0(s0)	# n bytes
    beqz s1, 3f
    lb a0, 1(s0)	# cmd
    addi s0, s0, 2
    call write_cmd
    addi s1, s1, -1
    mv a1, s1
    mv a0, s0
    call write_data
    add s0, s0, s1
    j 1b

3:  li a0, SLPOUT
    call write_cmd       # Exit sleep
    li a0, 100
    call delayms
    li a0, DISPLAY_ON
    call write_cmd    # Display on
    li a0, 100
    call delayms

    lw ra, 0(sp)
    lw s0, 4(sp)
  	lw s1, 8(sp)
	addi sp, sp, 12
    ret

.globl ili9341_init
ili9341_init:
	pushra
	call spi1_init

	li a0, CS_PIN
	call pin_output
	li a0, DC_PIN
	call pin_output
	li a0, RST_PIN
	call pin_output

    # call res_high
    call cs_high
    call dc_low
    call rst_low
    li a0, 50
    call delayms
    call rst_high
    li a0, 50
    call delayms

	call init_commands

	popra
	ret

# a0 r a1 g a2 b return rgb in a0
rgb_565:
	# convert to 565 rrrrrggg gggbbbbb
    # ((aR & 0xF8) << 8) | ((aG & 0xFC) << 3) | (aB >> 3)
    andi t0, a0, 0xF8
    slli t0, t0, 8
    andi t1, a1, 0xFC
    slli t1, t1, 3
    or t0, t0, t1
    srli t1, a2, 3
	or a0, t0, t1 		# a0 : RGB565
	ret
# a0 has RGB 888, return RGB 565 in a0
rgb_888_565:
	li t0, 0xF80000
	and t0, a0, t0
	srli t0, t0, 8
	li t1, 0x00FC00
    and t1, a0, t1
    srli t1, t1, 5
    or t0, t0, t1
    andi t1, a0, 0x0000FF
    srli t1, t1, 3
	or a0, t0, t1 		# a0 : RGB565
	ret

# a0: xs, a1: xe, a2: ys, a3: ye, inclusive from xs to xe
.globl ili9341_set_window_location
ili9341_set_window_location:
	addi sp, sp, -28
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)
  	sw a0, 12(sp)
  	sw a1, 16(sp)
  	sw a2, 20(sp)
  	sw a3, 24(sp)

  	mv s1, a0		# save xs, xe
  	mv s2, a1

	li a0, SET_COLUMN
	call write_cmd
	la t1, spi_data
	rev8 s1, s1        # Reverse all 4 bytes as chip required bigendian
	srli s1, s1, 16
	sh s1, 0(t1)
	rev8 s2, s2        # Reverse all 4 bytes as chip required bigendian
	srli s2, s2, 16
	sh s2, 2(t1)
	la a0, spi_data
	li a1, 4
	call write_data

	li a0, SET_PAGE
	call write_cmd
	la t1, spi_data
	rev8 a2, a2        # Reverse all 4 bytes as chip required bigendian
	srli a2, a2, 16
	sh a2, 0(t1)
	rev8 a3, a3        # Reverse all 4 bytes as chip required bigendian
	srli a3, a3, 16    # place swapped halfword at LSB (16 bits)
	sh a3, 2(t1)
	la a0, spi_data
	li a1, 4
	call write_data

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw s2, 8(sp)
   	lw a0, 12(sp)
  	lw a1, 16(sp)
  	lw a2, 20(sp)
  	lw a3, 24(sp)
 	addi sp, sp, 28
  	ret

# a0: rgb in 565
.globl ili9341_clearscreen
ili9341_clearscreen:
	pushra
  	mv t6, a0

	mv a0, zero
	li a1, ILI9341_WIDTH-1
	mv a2, zero
	li a3, ILI9341_HEIGHT-1
	call ili9341_set_window_location

	# write color data
    li a0, WRITE_RAM
    call write_cmd
    mv a0, t6
    li a1, ILI9341_SCREEN_SIZE
    call write_data16n

    popra
  	ret

# a0: xs, a1: xe, a2: ys, a3: ye a4: color
.globl ili9341_fillrect
ili9341_fillrect:
	pushra
	call ili9341_set_window_location

	sub t0, a1, a0	# xsize
	addi t0, t0, 1
	sub t1, a3, a2	# ysize
	addi t1, t1, 1
	mul t6, t0, t1	# n writes

	# write color data
    li a0, WRITE_RAM
    call write_cmd
    mv a0, a4
    mv a1, t6
    call write_data16n
    popra
    ret

# a0: xs, a1: xe, a2: ys, a3: ye, a4: buf
.globl ili9341_blit
ili9341_blit:
	pushra
	call ili9341_set_window_location

	sub t0, a1, a0	# xsize
	addi t0, t0, 1
	sub t1, a3, a2	# ysize
	addi t1, t1, 1
	mul t6, t0, t1	# n writes
	slli t6, t6, 1 	# * 2

    li a0, WRITE_RAM
    call write_cmd
	mv a0, a4
	mv a1, t6
    call write_data
    popra
    ret

.section .rodata
.p2align 2
.include "font16.s"

.section .text

# fetch the base address of the character in a0
# and render it into the memory at a1
render_char:
	la t0, font16
	li t1, FONT16_STRIDE
	li t2, FONT16_HEIGHT
	mul t1, t1, t2
	addi t2, a0, -32 	# starts at ' '
	mul t1, t2, t1
	add t0, t0, t1 		# address of the character
    la t1, fg_color
    lh t4, 0(t1)		# get foreground color
   	rev8 t4, t4
	srli t4, t4, 16 	# swap nibbles
    la t1, bg_color
    lh t5, 0(t1)		# get background color
   	rev8 t5, t5
	srli t5, t5, 16 	# swap nibbles
    li t6, FONT16_HEIGHT
4:  li t3, FONT16_WIDTH
	# convert the bits into 16bits 565 RGB
	lh t1, 0(t0)		# load 16 bits b1b0
	rev8 t1, t1 		# b0b10000 make it left aligned with first bit MSBit
1:	bexti t2, t1, 31 	# test MSBit
	beqz t2, 2f
	sh t4, 0(a1)		# fgcolor
	j 3f
2:	sh t5, 0(a1)		# bgcolor
3:	slli t1, t1, 1 		# next bit
	addi a1, a1, 2 		# next dest address
	addi t3, t3, -1 	# count width down
	bnez t3, 1b
	addi t0, t0, FONT16_STRIDE
	addi t6, t6, -1
	bnez t6, 4b
	ret

.section .bss
.p2align 1
# big enough for 11x16 font
tft_char_buf: .dcb.w FONT16_WIDTH*FONT16_HEIGHT

.section .text
# a0 char, a1 xpos, a2 ypos
.globl tft_putchar
tft_putchar:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	mv s1, a1
	la a1, tft_char_buf
	call render_char

	addi a1, s1, FONT16_WIDTH-1		# xe
	addi a3, a2, FONT16_HEIGHT-1	# ye
	mv a0, s1
	la a4, tft_char_buf
	call ili9341_blit

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret

# a0 zstring, a1 xpos, a2 ypos
# wraps to next line if it goes over screen width
# returns: a0 next char pos, a1 last x, a2 last y
.globl tft_putstr
tft_putstr:
	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)
  	sw s3, 12(sp)

	mv s1, a0		# sptr
	mv s2, a1 		# x
	mv s3, a2 		# y

1:	lb a0, 0(s1)
	beqz a0, 3f
	li t0, 10 		# nl
	beq a0, t0, 2f
	mv a1, s2
	mv a2, s3
	call tft_putchar

	addi s1, s1, 1
	addi s2, s2, FONT16_WIDTH
	li t0, ILI9341_WIDTH - FONT16_WIDTH
	blt s2, t0, 1b
	# wrap to next line
4:	mv s2, zero
	addi s3, s3, FONT16_HEIGHT
	j 1b
	# handle newline
2:	addi s1, s1, 1
	j 4b

3: 	mv a0, s1
	mv a1, s2
	mv a2, s3

	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw s2, 8(sp)
  	lw s3, 12(sp)
  	addi sp, sp, 16
	ret

# display the number in a0 at char pos x in a1 and line in a2
.globl tft_printn
tft_printn:
	pushra
	mv t6, a1
	la a1, numbuf
    call int2str
	la a0, numbuf
	li t0, FONT16_WIDTH
	mul a1, t6, t0
	li t0, FONT16_HEIGHT
	mul a2, a2, t0
	call tft_putstr
	popra
	ret

# print the zstring in a0 at char pos x in a1 and line in a2
# returns line in a2 and next x character pos in a1
.globl tft_printstr
tft_printstr:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li t0, FONT16_WIDTH
	mul a1, a1, t0
	li t0, FONT16_HEIGHT
	mul a2, a2, t0

	call tft_putstr

	li t0, FONT16_WIDTH
	div a1, a1, t0
	li t0, FONT16_HEIGHT
	div a2, a2, t0

 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# clear the line specified in a0 to 0
.globl tft_clear_line
tft_clear_line:
	pushra
	mv t0, a0
	li a0, 0
	li a1, ILI9341_WIDTH-1
	li t1, FONT16_HEIGHT
	mul a2, t0, t1
	addi a3, a2, FONT16_HEIGHT-1
	li a4, 0 						# color to fill with
	call ili9341_fillrect
	popra
	ret

.globl test_tft
test_tft:
	call ili9341_init

	j test_tft_char

1:	li a0, 0
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0xFF0000
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0x00FF00
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0x0000FF
	call rgb_888_565
	call ili9341_clearscreen
	li a0, 1000
	call delayms

	li a0, 0xFFFFFF
	call rgb_888_565
	mv a4, a0

	li a0, 20
	li a1, 20+20-1
	li a2, 20
	li a3, 20+20-1
	call ili9341_fillrect
	li a0, 1000
	call delayms

	j 1b
	ret

.globl test_tft_char
test_tft_char:
	# call ili9341_init

	li a0, 0
	call ili9341_clearscreen

	# set color for font
	li a0, 0xFFFFFF
	call rgb_888_565
	la t1, fg_color
	sh a0, 0(t1)
	li a0, 0x000000
	call rgb_888_565
	la t1, bg_color
	sh a0, 0(t1)

	# display all characters
	li s1, ' '	# char
	li s2, 0 	# x
	li s3, 20 	# y
	li s4, 16 	# cnt/line

1:	mv a0, s1
	mv a1, s2
	mv a2, s3
	call tft_putchar

	addi s1, s1, 1
	li t0, '~'
	bgt s1, t0, 2f
	addi s2, s2, FONT16_WIDTH
	addi s4, s4, -1
	bnez s4, 1b
	li s2, 0
	addi s3, s3, FONT16_HEIGHT
	li s4, 16
	j 1b

2:	la a0, hello_string
	li a1, 0
	li a2, 0
	call tft_printstr

	la a0, str2
	li a1, 0
	li a2, 10
	call tft_printstr

	la a0, hello_string
	call tft_printstr
	li a0, 2000
	call delayms

	li s1, 0
4:	mv a0, s1
	li a1, 0
	li a2, 12
	call tft_printn
	addi s1, s1, 1
	li t0, 100
	bne t0, s1, 5f
	li a0, 11
	call tft_clear_line
5:	li a0, 50
	call delayms
	j 4b

3:	j 3b
	ret

.section .rodata
hello_string: .asciz "Hello World!"
str2: .asciz "One Line\nNext line"

.section .bss
numbuf: .dcb.b 20
