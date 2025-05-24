.section .text
# Inputs:
#   a1:a0 = 64 bit dividend (hi:lo)
#   a2 = 32 bit divisor
# Returns:
#   a0 = quotient
# Note a1 < a2 otherwise we get overflow (a0 = 0xFFFFFFFF)
# This is an unsigned divide
#
# This algorithm is taken from Hacker's Delight 2nd Edition divlu2
# https://github.com/hcs0/Hackers-Delight/tree/master
# based on Knuths algorithms
#
.globl div64u
div64u:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw s1, 4(sp)
	sw s2, 8(sp)
  	sw s3, 12(sp)
  	sw s4, 16(sp)

   	bnez a2, 1f
  	# divide by zero
  	mv a0, zero
  	j div64_exit

    # If high word is zero, a simple 32-bit division is enough
    bnez a1, 1f
    divu a0, a0, a2
    j div64_exit

1:	blt a1, a2, 2f
	# overflow
	li a0, 0xFFFFFFFF
	j div64_exit

2:	clz t0, a2 			# s
	sll a2, a2, t0 		# normalize divisor
	srl t1, a2, 16 		# vn1
	li t2, 0xFFFF
	and t2, a2, t2		# vn0 break divisor into 2 16bit digits

	# shift dividend by same amount as divisor
	sll t3, a1, t0		# (u1 << s)
	li t4, 32
	sub t4, t4, t0
	srl t4, a0, t4		# (u0 >> 32 - s)
	neg t5, t0
	srai t5, t5, 31 	# (-s >> 31)
	and t4, t4, t5
	or t3, t3, t4 		# un32 = (u1 << s) | (u0 >> 32 - s) & (-s >> 31)

	sll t4, a0, t0 		# un10 = u0 << s Shift dividend left
	srli t5, t4, 16 	# un1
	li t6, 0xFFFF
	and t4, t4, t6	 	# un0 break dividend into 2 digits
	divu t6, t3, t1 	# q1
	mul s1, t6, t1
	sub s1, t3, s1		# rhat first quotient digit

	li s2, 65536		# again1:
4:	bge t6, s2, 5f		# q1 >= 65536
	mul s3, t6, t2		# q1 * vn0
	mul s4, s1, s2		# 65536 * rhat
	add s4, s4, t5		#  + un1
	bgt s3, s4, 5f		#   >
	j 6f
5:  addi t6, t6, -1		# q1 = q1 - 1
	add s1, s1, t1		# rhat = rhat + vn1
	blt s1, s2, 4b		# if rhat < 65536 goto again1
6:	mul t3, t3, s2		# un32 * 65536
	mul s4, t6, a2		# q1 * v
	add t3, t3, t5		#  + un1
	sub t3, t3, s4		# un21 = ((un32 * b) + un1) - (q1 * v)
	div s3, t3, t1		# q0 = un21 / vn1 compute the second quotient
	mul s1, s3, t1		# q0 * vn1
	sub s1, t3, s1		# rhat = un21 - (q0 * vn1)

7:	bge s3, s2, 8f		# again2: q0 >= 65536
	mul s4, s3, t2		# q0 * vn0
	mul a1, s1, s2		# 65536 * rhat
	add a1, a1, t4		#  + un0
	bgt s4, a1, 8f		#   >
	j 9f
8:	addi s3, s3, -1		# q0 = q0 - 1
	add s1, s1, t1		# rhat = rhat + vn1
	blt s1, s2, 7b		# if (rhat < 65536) goto again2
	# r = (un21 * b + un0 - q0 * v) >> s; if remainder is wanted

9:	mul a0, t6, s2		# q1 * b
	add a0, a0, s3		# result: quotient = q1 * b + q0

div64_exit:
  	lw ra, 0(sp)
  	lw s1, 4(sp)
 	lw s2, 8(sp)
  	lw s3, 12(sp)
  	lw s4, 16(sp)
  	addi sp, sp, 20
    ret

# signed divide 64 / 32 with 32 result
# a1:a0 / a2 --> a0
#
.globl div64s
div64s:
	addi sp, sp, -4
  	sw ra, 0(sp)

  	# save if we need to negate result
	# if a1<0 xor a2<0 then negate quotient
	bexti t0, a1, 31
	bexti t1, a2, 31
	xor a3, t0, t1
  	# make dividend absolute
	call fpabs
 	# make divisor absolute
 	bgez a2, 1f
 	neg a2, a2

 	# call unsigned divide
1:	call div64u

	# check if we need to negate result
    beqz a3, 2f
	# negate the quotient in a0
    neg a0, a0

2: 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# multiply a0 by a1 then divide the resulting 64bit by a2 to get a 32 bit result
# a0 * a1 / a2 with intermediate 64 bit result
.globl mul64_div
mul64_div:
  	# do 32x32 -> 64 multiply
    mul a0, a1, a0
    mulh a1, a1, a0
    j div64s

.globl test_div64
test_div64:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	call uart_init
	# test divide
	li a0, 0x00010000
	li a1, 65535
	li a2, 65536
	call div64s
	call uart_print8hex
	call uart_printspc
	call uart_printn
	call uart_printnl

	# test multiply
	li a0, 65536
	li a1, 65536
	li a2, 65536
	call mul64_div
	call uart_print8hex
	call uart_printspc
	call uart_printn
	call uart_printnl


1: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret
