# driver for mini-imu 9
# L3GD20 gyro
# LSM303DLHC mag and accelerometer

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
.p2align 1
i2cbuf: .dcb.b 16

.section .text
# a0 i2caddr, a1 reg returns val in a0, 0x8000 if an error
.globl mimu_get_reg
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

# a0 i2caddr, a1 reg, a2 val, returns 0 in a0 if ok
.globl mimu_writereg
mimu_writereg:
	addi sp, sp, -4
  	sw ra, 0(sp)
	la t0, i2cbuf
	sb a1, 0(t0)
	sb a2, 1(t0)
	la a1, i2cbuf
	li a2, 2
	call i2c_write
 	lw ra, 0(sp)
  	addi sp, sp, 4
  	ret

# a0 i2caddr, a1 reg, a2 nvals, returns 0 in a0 if ok
# results are in i2cbuf
.globl mimu_get_regs
mimu_get_regs:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)

  	mv s1, a0
  	mv s2, a2

	la t0, i2cbuf
	sb a1, 0(t0)
	la a1, i2cbuf
	li a2, 1
	call i2c_write_nostop
	bnez a0, 1f

	mv a0, s1
	la a1, i2cbuf
	mv a2, s2
	call i2c_read_restart

1: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw s2, 8(sp)
  	addi sp, sp, 12
  	ret

# should return 0xD4
.globl who_am_i
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

# returns a0 = 0 if ok
.globl gyro_init
gyro_init:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	li a0, GYRO_ADDR
  	li a1, L3G_CTRL_REG1
  	li a2, 0x0F
  	call mimu_writereg 	# enable all, 100 hz
  	bnez a0, 1f
	li a0, GYRO_ADDR
	li a1, L3G_CTRL_REG2
	li a2, 0x00
	call mimu_writereg 	# high pass filter
	bnez a0, 1f
	li a0, GYRO_ADDR
	li a1, L3G_CTRL_REG3
	li a2, 0x00
	call mimu_writereg
	bnez a0, 1f
	li a0, GYRO_ADDR
	li a1, L3G_CTRL_REG4
	li a2, 0x00
	call mimu_writereg 	# 250 dps
	bnez a0, 1f
	li a0, GYRO_ADDR
	li a1, L3G_CTRL_REG5
	li a2, 0x00
	call mimu_writereg
	bnez a0, 1f

1: 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# returns gx, gy, gz in a0, a1, a2
.globl read_gyro
read_gyro:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	li a0, GYRO_ADDR
  	li a1, L3G_OUT_X_L | 0x80
  	li a2, 6
  	call mimu_get_regs
  	bnez a0, 1f
  	la t0, i2cbuf
  	# lbu t1, 0(t0)	# lb
  	# lb t2, 1(t1)	# hb
  	# slli t2, t2, 8
  	# or t1, t1, t2
  	lh a0, 0(t0)	# as it is little endian we can just read the halfword
  	lh a1, 2(t0)
  	lh a2, 4(t0)
  	j 2f

  	# read error
1:	mv a0, zero
	mv a1, zero
	mv a2, zero

2:	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.globl acc_mag_init
# returns a0 = 0 if ok
acc_mag_init:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	li a0, ACCEL_ADDR
  	li a1, LSM303_CTRL_REG1_A
  	li a2, 0x47
  	call mimu_writereg 	# 50 hz
  	bnez a0, 1f

  	li a0, ACCEL_ADDR
  	li a1, LSM303_CTRL_REG4_A
  	li a2, 0x00
  	call mimu_writereg 	# +/-2g 1mg/LSB
  	bnez a0, 1f

  	li a0, MAG_ADDR
  	li a1, LSM303_MR_REG_M
  	li a2, 0x00
  	call mimu_writereg
  	bnez a0, 1f

  	li a0, MAG_ADDR
  	li a1, LSM303_CRA_REG_M
  	li a2, 0x08
  	call mimu_writereg
  	bnez a0, 1f

  	li a0, MAG_ADDR
  	li a1, LSM303_CRB_REG_M
  	li a2, 0x20
  	call mimu_writereg
  	bnez a0, 1f

1: 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.globl read_acc
# returns ax, ay, az in a0, a1, a2
read_acc:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	li a0, ACCEL_ADDR
  	li a1, LSM303_OUT_X_L_A | 0x80
  	li a2, 6
  	call mimu_get_regs
  	bnez a0, 1f
  	la t0, i2cbuf
  	lh a0, 0(t0)	# as it is little endian (L,H) we can just read the halfword
  	lh a1, 2(t0)
  	lh a2, 4(t0)
  	# adjust for 12-bit resolution, left-aligned when read
  	srai a0, a0, 4
  	srai a1, a1, 4
  	srai a2, a2, 4
  	j 2f

  	# read error
1:	mv a0, zero
	mv a1, zero
	mv a2, zero

2:	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.globl read_mag
# returns mx, my, mz in a0, a1, a2
read_mag:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	li a0, MAG_ADDR
  	li a1, LSM303_OUT_X_H_M
  	li a2, 6
  	call mimu_get_regs
  	bnez a0, 1f
  	la t0, i2cbuf
  	lh a0, 0(t0)	# as it is big endian (H,L) we will need to swap the bytes
  	lh a1, 2(t0)
  	lh a2, 4(t0)
  	# swap the bytes
   	rev8 a0, a0
	srai a0, a0, 16
   	rev8 a1, a1
	srai a1, a1, 16
   	rev8 a2, a2
	srai a2, a2, 16
  	j 2f
  	# read error
1:	mv a0, zero
	mv a1, zero
	mv a2, zero

2:	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

