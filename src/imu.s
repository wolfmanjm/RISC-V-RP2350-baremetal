# driver for mini-imu 9
.equ GYRO_ADDR, 0x6B   # L3GD20 gyro
.equ ACCEL_ADDR, 0x19  # LSM303DLHC_DEVICE accel
.equ MAG_ADDR, 0x1E    # LSM303DLHC_DEVICE magno

.equ LSM303_CTRL_REG1_A, 0x20
.equ LSM303_CTRL_REG2_A, 0x21
.equ LSM303_CTRL_REG3_A, 0x22
.equ LSM303_CTRL_REG4_A, 0x23
.equ LSM303_CTRL_REG5_A, 0x24
.equ LSM303_CTRL_REG6_A, 0x25
.equ LSM303_CRA_REG_M, 0x00
.equ LSM303_CRB_REG_M, 0x01
.equ LSM303_MR_REG_M, 0x02
.equ LSM303_OUT_X_H_M, 0x03
.equ LSM303_OUT_X_L_A, 0x28
.equ LSM303_OUT_X_H_A, 0x29
.equ LSM303_OUT_Y_L_A, 0x2A
.equ LSM303_OUT_Y_H_A, 0x2B
.equ LSM303_OUT_Z_L_A, 0x2C
.equ LSM303_OUT_Z_H_A, 0x2D
.equ LSM303_TEMP_OUT_H_M, 0x31
.equ LSM303_TEMP_OUT_L_M, 0x32

.equ L3G_WHOAMI, 0x0F
.equ L3G_OUT_TEMP, 0x26
.equ L3G_CTRL_REG1, 0x20
.equ L3G_CTRL_REG2, 0x21
.equ L3G_CTRL_REG3, 0x22
.equ L3G_CTRL_REG4, 0x23
.equ L3G_CTRL_REG5, 0x24
.equ L3G_OUT_X_L, 0x28
.equ L3G_OUT_X_H, 0x29
.equ L3G_OUT_Y_L, 0x2A
.equ L3G_OUT_Y_H, 0x2B
.equ L3G_OUT_Z_L, 0x2C
.equ L3G_OUT_Z_H, 0x2D

.section .data
i2cbuf: .dcb.b 16

.section .text
# a0 i2caddr, a1 reg returns val in a0, 0x8000 if an error
mimu_get_reg:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

  	mv s1, a0
	la t0, i2cbuf
	sb a1, 0(t0)
	la a1, i2cbuf
	li a2, 1
	call i2c_write_nostop
	beqz a0, 1f
	li a0, 0x8000
	j 4f
1:	mv a0, s1
	la a1, i2cbuf
	li a2, 1
	call i2c_read_restart
	beqz a0, 2f
	li a0, 0x8000
	j 4f
2:	la t0, i2cbuf
	lbu a0, 0(t0)

4: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
  	ret

# : mimu-writereg ( val reg addr -- )
# 	-rot
# 	mimu-i2cbuf c!
# 	mimu-i2cbuf 1+ c!
# 	2 mimu-i2cbuf rot i2c-writebuf if ." writereg failed" then
# ;

# \ returns requested registers in mimu-i2cbuf
# : mimu-get-regs ( n reg addr -- errflg )
# 	>r mimu-i2cbuf c!
# 	1 mimu-i2cbuf r> i2c-writebuf-nostop if ." getregs failed" true exit then
# 	mimu-i2cbuf i2c-readbuf-restart if ." getregs failed" true exit then
# 	false
# ;

# should return 0xD4
who_am_i:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li a0, GYRO_ADDR
	li a1, L3G_WHOAMI
	call mimu_get_reg

  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

read_temp:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li a0, GYRO_ADDR
	li a1, L3G_OUT_TEMP
	call mimu_get_reg

  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret


.globl test_imu
test_imu:
	addi sp, sp, -4
  	sw ra, 0(sp)

	call i2c_init
	call uart_init       # Initialize UART

    la a0, msg1          # Load address of message
    call uart_puts       # Print message

    call who_am_i
	la a1, t2buf
	call parse_2h
	la a0, t2buf
	call uart_puts

    la a0, msg2          # Load address of message
    call uart_puts       # Print message
    call read_temp
	la a1, t2buf
	call parse_2h
	la a0, t2buf
	call uart_puts

 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.section .data
msg1: .asciz "IMU Test\nWho am i: "
msg2: .asciz "\nTemp: "
t2buf: .dcb.b 16
