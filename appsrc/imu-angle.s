# An app to display the angle of the IMU
# Acc_angle = atan2(AcY, -AcX) * 57.295800000

.section .text
.globl main
main:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw s2, 8(sp)

	call i2c_init
	call uart_init       # Initialize UART

	call acc_mag_init
	bnez a0, 3f

1:	call read_acc
	mv s1, a0		# x
	mv s2, a1 		# y

	# convert to Fixed point
	mv a0, zero
	mv a1, s1		# x
	call fpneg 		# -x
	mv a2, a0
	mv a3, a1
	mv a0, zero
	mv a1, s2			# y
	call fp_atan2
	li a2, 0x4BB98C7E
	li a3, 0x00000039
	call fpmul			# * 57.2958
	call uart_printfp1
	call uart_printnl
	li a0, 200
	call delayms
	j 1b

3: 	lw ra, 0(sp)
 	lw s1, 4(sp)
 	lw s2, 8(sp)
  	addi sp, sp, 12
	ret
