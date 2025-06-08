.section .text
# a0 = lo (lower 32 bits)
# a1 = hi (upper 32 bits)
# a2 = n  (shift amount, 0 < n < 32)
d_lshift:
	sll  t0, a0, a2                # t0 = lo << n
	sll  t1, a1, a2                # t1 = hi << n
	li    t2, 32
	sub   t2, t2, a2                # t2 = 32 - n
	srl   t3, a0, t2                # t3 = lo >> (32 - n)
	or    a1, t1, t3                # new hi = (hi << n) | (lo >> (32 - n))
	mv    a0, t0                    # new lo = lo << n
	ret

# a0 = lo (lower 32 bits)
# a1 = hi (upper 32 bits)
# a2 = n  (shift amount, 0 < n < 32)
d_rshift:
	srl  t0, a0, a2                # t0 = lo >> n
	srl  t1, a1, a2                # t1 = hi >> n
	li    t2, 32
	sub   t2, t2, a2                # t2 = 32 - n
	sll   t3, a1, t2                # t3 = hi << (32 - n)
	or    a0, t0, t3                # new lo = (lo >> n) | (hi << (32 - n))
	mv    a1, t1                    # new hi = hi >> n
	ret


# a0 = lo (lower 32 bits)
# a1 = hi (upper 32 bits)
d_lshift1:
	slli  t0, a1, 1                # t0 = lo << n
	srli  t1, a0, 31               # t3 = lo >> (32 - n)
	or    a1, t0, t1               # new hi = (hi << n) | (lo >> (32 - n))
	slli  a0, a0, 1                # t1 = hi << n
	ret

# a0 = lo
# a1 = midlo
# a2 = midhi
# a3 = hi
q_lshift1:
	slli  t3, a3, 1
	srli  t4, a2, 31
	or    a3, t3, t4
	slli  t3, a2, 1
	srli  t4, a1, 31
	or    a2, t3, t4
	slli  t3, a1, 1
	srli  t4, a0, 31
	or    a1, t3, t4
	slli  a0, a0, 1
	ret

# 32-bit signed integer multiplication returning 64-bit product
#   arguments:
#       a0: x
#       a1: y
#   return:
#       a0: x*y lower 32 bits
#       a1: x*y upper 32 bits
#
mul_32_64:
    mulh    t0, a1, a0
    mul     a0, a1, a0
    mv      a1, t0
    ret

# 64 x 64 with 128bit result
# a1:a0 * a3:a2 result in a3:a2:a1:a0
# This is using long multiplication with 32bit words as each digit
# unsigned but with judicious use of mulhx we could make it signed
.globl mul_64_128u
mul_64_128u:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw s1, 4(sp)
	sw s2, 8(sp)
  	sw s3, 12(sp)
  	sw s4, 16(sp)

	mul s1, a0, a2 		# d1 of quotient
	mulhu t0, a0, a2	# carry
	mul t1, a1, a2
	mulhu t2, a1, a2
	# add in carry from previous
    add t1, t1, t0		# i1
    sltu t0, t1, t0
    add t2, t2, t0		# i2
    # next digit - current result s1
    mul t3, a3, a0
    mulhu t4, a3, a0
    add s2, t3, t1 		# d2 current result s2:s1
    sltu t0, s2, t1
    add t4, t4, t0
    # next digit
    mul t5, a3, a1
    mulhu t6, a3, a1
    add t5, t5, t4
    sltu t0, t5, t4
    add t6, t6, t0
    add s3, t5, t2		# d3 current result s3:s2:s1
    sltu t0, s3, t2
    add s4, t6, t0		# d4 final result s4:s3:s2:s1
    mv a0, s1
    mv a1, s2
    mv a2, s3
    mv a3, s4

  	lw ra, 0(sp)
  	lw s1, 4(sp)
 	lw s2, 8(sp)
  	lw s3, 12(sp)
  	lw s4, 16(sp)
  	addi sp, sp, 20

    ret
