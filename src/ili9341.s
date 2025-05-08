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

.section .data
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

spi_data: .dcb.b 4

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
	li t1, 0x00FC00
    and t1, a0, t1
    slli t1, t1, 3
    or t0, t0, t1
    andi t1, a0, 0x0000FF
    srli t1, t1, 3
	or a0, t0, t1 		# a0 : RGB565
	ret

# a0: rgb in 565
.globl ili9341_clearscreen
ili9341_clearscreen:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s0, 4(sp)

  	mv s0, a0 			# save RGB
	# set window location
	li a0, SET_COLUMN
	call write_cmd
	la t1, spi_data
	sh zero, 0(t1)
	li t2, ILI9341_WIDTH-1
	rev8 t2, t2        # Reverse all 4 bytes as chip required bigendian
	srli t2, t2, 16    # place swapped halfword at LSB (16 bits)
	sh t2, 2(t1)
	la a0, spi_data
	li a1, 4
	call write_data

	li a0, SET_PAGE
	call write_cmd
	la t1, spi_data
	sh zero, 0(t1)
	li t2, ILI9341_HEIGHT-1
	rev8 t2, t2        # Reverse all 4 bytes as chip required bigendian
	srli t2, t2, 16    # place swapped halfword at LSB (16 bits)
	sh t2, 2(t1)
	la a0, spi_data
	li a1, 4
	call write_data

	# write color data
    li a0, WRITE_RAM
    call write_cmd
    mv a0, s0
    li a1, ILI9341_SCREEN_SIZE
    call write_data16n

  	lw ra, 0(sp)
  	lw s0, 4(sp)
  	addi sp, sp, 8
  	ret

.globl test_tft
test_tft:
	call ili9341_init

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

	j test_tft
	ret
