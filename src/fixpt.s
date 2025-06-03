# This does S31.32 fixed point arithmetic for risc-v

# Inputs:
#   a0 = a_lo
#   a1 = a_hi
#   a2 = b_lo
#   a3 = b_hi
# Output:
#   a0 = result_lo
#   a1 = result_hi
.globl fpmul
fpmul:
	addi sp, sp, -12
  	sw ra, 0(sp)
  	sw s0, 4(sp)
	sw s1, 8(sp)

    mul     t0, a0, a2        # t0 = A_lo * B_lo (low 32 bits)
    mulhu   t1, a0, a2        # t1 = A_lo * B_lo (high 32 bits)
    mul     t2, a1, a2        # t2 = A_hi * B_lo (low)
    mul     t3, a0, a3        # t3 = A_lo * B_hi (low)
    add     t4, t2, t3        # t4 = mid1 + mid2
    sltu    t5, t4, t2        # t5 = carry from the addition
    add     t1, t1, t4        # t1 = t1 + mid_sum_lo
    add     t1, t1, t5        # t1 = add carry from mid_sum
    mul     t6, a1, a3        # t6 = A_hi * B_hi
    mulhu   s0, a1, a2        # s0 = upper 32 bits of A_hi * B_lo
    mulhu   s1, a0, a3        # s1 = upper 32 bits of A_lo * B_hi
    add     t6, t6, s0
    add     t6, t6, s1
    add     t6, t6, t5        # account for possible carry in mid_sum

    # Result:
    # t0 = low 32 bits of result
    # t1 = mid 32 bits
    # t6 = high 64-bit result upper half

    mv a0, t1
    mv a1, t6

  	lw ra, 0(sp)
  	lw s0, 4(sp)
 	lw s1, 8(sp)
  	addi sp, sp, 12
    ret

# Inputs:
#   a1:a0 = dividend (signed S31.32)
#   a3:a2 = divisor (signed S31.32)
# Returns:
#   a1:a0 = quotient (signed S31.32)
#
.globl fpdiv
fpdiv:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw s1, 4(sp)
	sw s2, 8(sp)
  	sw s3, 12(sp)
  	sw s4, 16(sp)

  	or t0, a2, a3
  	bnez t0, 1f
  	# divide by zero
  	mv a0, zero
  	mv a1, zero
  	j div_exit

  	# save signs
1: 	mv s1, a1
  	mv s2, a3

    # Build the abs 96‑bit numerator = (dividend << 32)
    call fpabs
 	mv t0, zero      # t0 = num_low  = 0
    mv t1, a0
    mv t2, a1

    # Absolute‑value the 64‑bit denominator in [a3:a2]
    mv a0, a2
    mv a1, a3
    call fpabs
    mv a2, a0
    mv a3, a1

    # Prepare quotient = 0
    mv t3, zero        # t3 = quot_lo
    mv t4, zero        # t4 = quot_hi

    # Prepare remainder = 0
    mv t5, zero        # t5 = rem_lo
    mv t6, zero        # t6 = rem_hi

    # Long‐division loop for 96 ÷ 64
    li s3, 96          # bit‑count

 div_loop:
 	# shift remainder left 1
 	slli t6, t6, 1
	srli s4, t5, 31
	or t6, t6, s4
	slli t5, t5, 1
	# extract MSbit from numerator and then or into lsb of remainder
	bexti s4, t2, 31
	or t5, t5, s4
	# shift numerator left 1 [t2:t1:t0] <<= 1
    sll t2, t2, 1
    srl s4, t1, 31
    or t2, t2, s4
    sll t1, t1, 1
    srl s4, t0, 31
    or t1, t1, s4
    sll t0, t0, 1

    # shift quotient left
    slli t4, t4, 1
	srli s4, t3, 31
	or t4, t4, s4
	slli t3, t3, 1

    # Compare remainder(t6:t5) >= divisor(a3:a2)
    bgtu t6, a3, div_sub
    bltu t6, a3, 1f
    bgeu t5, a2, div_sub
1:	# decrement counter
	addi s3, s3, -1
	bnez s3, div_loop
	j div_done

div_sub:
	# remainder -= divisor
	sltu s4, t5, a2       # Set s4 = 1 if a borrow will occur
    sub  t5, t5, a2       # Subtract lower 32 bits
    sub  t6, t6, a3       # Subtract upper 32 bits
    sub  t6, t6, s4       # Subtract borrow from upper 32 bits
	# quotient |= 1
	ori t3, t3, 1
	j 1b

div_done:
	# returns quotient
	mv a0, t3
	mv a1, t4
	# if s1<0 xor s2<0 then negate quotient
	bexti t0, s1, 31
	bexti t1, s2, 31
	xor t0, t0, t1
    beqz t0, div_exit
    # negate the results
    call fpneg

div_exit:
  	lw ra, 0(sp)
  	lw s1, 4(sp)
 	lw s2, 8(sp)
  	lw s3, 12(sp)
  	lw s4, 16(sp)
  	addi sp, sp, 20
    ret

# Inputs:
#   a0 = lhs low 32 bits
#   a1 = lhs high 32 bits
#   a2 = rhs low 32 bits
#   a3 = rhs high 32 bits
# Output:
#   a0 = result low 32 bits
#   a1 = result high 32 bits
.globl dadd
dadd:
.globl fpadd
fpadd:
    add     a0, a0, a2          # low part
    sltu    t0, a0, a2          # carry from low?
    add     a1, a1, a3
    add     a1, a1, t0          # add carry
    ret

# Inputs:
#   a0 = lhs low 32 bits
#   a1 = lhs high 32 bits
#   a2 = rhs low 32 bits
#   a3 = rhs high 32 bits
# Output:
#   a0 = result low 32 bits
#   a1 = result high 32 bits
.globl dsub
dsub:
.globl fpsub
fpsub:
    sltu t0, a0, a2       # Set t0 = 1 if a borrow will occur (a0 < a2)
    sub  a0, a0, a2       # Subtract lower 32 bits: a0 = a0 - a2
    sub  a1, a1, a3       # Subtract upper 32 bits
    sub  a1, a1, t0       # Subtract borrow from upper 32 bits
    ret

# negate fp number in a0/a1
.globl dneg
dneg:
.globl fpneg
fpneg:
    not a0, a0          # Invert lower 32 bits
    not a1, a1          # Invert upper 32 bits
    addi a0, a0, 1      # Add 1 to lower half
    # Check if there was a carry (a0 became zero after addition)
    seqz t0, a0         # t0 = 1 if a0 == 0 (i.e., carry occurred)
    add a1, a1, t0      # Add carry to upper half
    ret

# return abs of a0:a1 in a0:a1
.globl dabs
dabs:
.globl fpabs
fpabs:
    bgez a1, 1f  		# sign_z
	# negate
    not a0, a0          # Invert lower 32 bits
    not a1, a1          # Invert upper 32 bits
    addi a0, a0, 1      # Add 1 to lower half
    # Check if there was a carry (a0 became zero after addition)
    seqz t0, a0         # t0 = 1 if a0 == 0 (i.e., carry occurred)
    add a1, a1, t0      # Add carry to upper half
1: 	ret

# approximation of atan2() where |error| < 0.005
# Input: a1:a0 = y (S31.32), a3:a2 = x (S31.32)
# Output: a1:a0 = atan2(y, x) (S31.32)
.globl fp_atan2
fp_atan2:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw s1, 4(sp)
	sw s2, 8(sp)
  	sw s3, 12(sp)
  	sw s4, 16(sp)

    # --- Special case: x == 0 ---
    or t2, a2, a3
    bnez t2, do_div

    # If y == 0 → return 0
    or t2, a1, a0
    bnez t2, 1f
  	li a0, 0
  	li a1, 0
  	j atan2done

    # If y > 0 → return π/2
    # If y < 0 → return -π/2
1:  bgtz    a1, 2f
	li      a0, 0x6DE04ABC     # -π/2 low
    li      a1, 0xFFFFFFFE     # -π/2 high
    j 		atan2done
2:  li      a0, 0x921FB544     # π/2 low
    li      a1, 0x00000001     # π/2 high
    j 		atan2done

do_div:
	mv s3, a1 			# save y high
	mv s4, a3 			# save x high

    # fpdiv(y, x)
    # z = y / x
    call    fpdiv
    # Save z in s1:s2 L:H
    mv      s1, a0
    mv      s2, a1

    # fabs(z)
    call fpabs
    beqz a1, 1f 		# fabs(z) < 1.0
    # >= 1.0
    # atan = PIBY2_FLOAT - (z / ((z * z) + 0.28f));
    mv a0, s1
    mv a1, s2
    mv a2, s1
    mv a3, s2
    call fpmul 				# z * z
    li a2, 0x47AE147A 		# 0.28
	li a3, 0x00000000
	call fpadd 				# + 0.28
	mv a2, a0
	mv a3, a1
	mv a0, s1
	mv a1, s2
	call fpdiv
	mv a2, a0
	mv a3, a1
    li a0, 0x921FB544     	# π/2
    li a1, 0x00000001
    call fpsub 				# atan
    bgez s3, atan2done 		# y >= 0.0
    li a2, 0x243F6A88 		# π
	li a3, 0x00000003
	call fpsub 				# atan - π
    j atan2done

    # < 1.0
    # atan = z / (1.0f + (0.28f * z * z));
1:	mv a0, s1
    mv a1, s2
    mv a2, s1
    mv a3, s2
    call fpmul 				# z * z
    li a2, 0x47AE147A 		# 0.28
	li a3, 0x00000000
	call fpmul 				# * 0.28
	mv a2, zero
	li a3, 1 				# 1.0
	call fpadd 				# + 1.0
	mv a2, a0
	mv a3, a1
	mv a0, s1
    mv a1, s2
    call fpdiv 				# atan
    bgez s4, atan2done      # x >= 0.0
    li a2, 0x243F6A88 		# π
	li a3, 0x00000003
    bltz s3, 2f 			# y < 0.0
	call fpadd 				# atan + π
	j atan2done
2:	call fpsub 				# atan - π

atan2done:
  	lw ra, 0(sp)
  	lw s1, 4(sp)
 	lw s2, 8(sp)
  	lw s3, 12(sp)
  	lw s4, 16(sp)
  	addi sp, sp, 20
    ret

# convert the floating number in string at a0, into S31.32 a1:a0
# only handles absolute so strip preceding - and negate after
.globl str2fp
str2fp:
	addi sp, sp, -20
  	sw ra, 0(sp)
  	sw s0, 4(sp)
	sw s1, 8(sp)
  	sw s2, 12(sp)
  	sw s3, 16(sp)
  	# inialize
    li s0, 0 			# int_part = 0
    li s1, 0          	# frac_part = 0
    li s2, 1 			# DP divisor
    li s3, 0          	# flag = 0 (before dot)

1: 	lb t0, 0(a0)
	beqz t0, 4f
	addi a0, a0, 1

    # check for period
    li t1, '.'
    bne t0, t1, 2f
    li s3, 1
    j 1b

    # Convert ASCII to digit
2:  li t1, '0'
    sub t1, t0, t1    # t1 = digit (char - '0')
    li t0, 10
    # If before period, build int_part
    beqz s3, 3f

    mul s1, s1, t0
    add s1, s1, t1
	# digit divisor
    mul s2, s2, t0
    j 1b

3:  mul s0, s0, t0
    add s0, s0, t1
    j 1b

4:
    # s0 = int_part
    # s1 = frac_part = fp = s0, (s1<<32) / 10^ndigits
    mv a0, zero
    beqz s1, 5f 	# if nothing after the dot
    mv a1, s1
	mv a2, s2 		# dp divisor
	call div64u		# return a0 as the fractional part of the FP
5:	mv a1, s0 		# returns S31.32 Fixed point number

  	lw ra, 0(sp)
  	lw s0, 4(sp)
 	lw s1, 8(sp)
  	lw s2, 12(sp)
  	lw s3, 16(sp)
  	addi sp, sp, 20
    ret

# print fixed point number in hex a0 Lower, a1 Upper
# preserves a0/a1
.globl uart_printfphex
uart_printfphex:
	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw a0, 8(sp)
  	sw a1, 12(sp)

	mv s1, a0
	mv a0, a1
	call uart_print8hex
	li a0, '_'
	call uart_putc
	mv a0, s1
	call uart_print8hex

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw a0, 8(sp)
  	lw a1, 12(sp)
  	addi sp, sp, 16
	ret


.globl uart_printfp
# Arguments:
#   a0 = lower 32 bits fractional part
#   a1 = upper 32 bits integer part
# Prints:
#   S31.32 value as signed decimal to uart_putc (with 6 digits after decimal)
# preserves a0/a1
uart_printfp:
	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw s1, 4(sp)
  	sw a0, 8(sp)
  	sw a1, 12(sp)

    bgez a1, 1f 		# see if negative
    # negate it and print '-''
	mv 		s1, a0
    li      a0, '-'		# print -
    call    uart_putc

    not a0, s1          # Invert lower 32 bits
    not a1, a1          # Invert upper 32 bits
    addi a0, a0, 1      # Add 1 to lower half
    # Check if there was a carry (a0 became zero after addition)
    seqz t0, a0         # t0 = 1 if a0 == 0 (i.e., carry occurred)
    add a1, a1, t0      # Add carry to upper half

    # Print integer part in a1
1:	mv s1, a0
    mv a0, a1
    call uart_printun	 # prints integer part unsigned

    # Print dot
    li a0, '.'
    call uart_putc
    mv a0, s1

    # Extract 6 decimal digits from fractional (a0)
    # Multiply a0 (fraction) by 10^6 and shift >> 32
    # Result = (a0 * 1000000) >> 32
    li      t3, 1000000
    mulhu   a0, a0, t3
    # Now a0 contains fractional decimal digits (0..999999)
    # We'll print 6 digits with leading zeros
    li      t4, 100000
    li      t5, 10
    li      t6, 6           # digit count
2:  divu    t1, a0, t4      # digit = a0 / t4
    remu    a0, a0, t4      # remainder
    mv 		s1, a0
    addi    a0, t1, '0'
    call    uart_putc
    mv 		a0, s1
    divu    t4, t4, t5
    addi    t6, t6, -1
    bnez    t6, 2b

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	lw a0, 8(sp)
  	lw a1, 12(sp)
  	addi sp, sp, 16
    ret

# reads a fp number from uart, handles negative numbers by skipping the -
# and negating at end if needed
.globl uart_getfp
uart_getfp:
	addi sp, sp, -4
  	sw ra, 0(sp)

1:	la a0, inpstr
  	call uart_gets		# read line into inpstr
  	bnez a0, 2f
  	li a0, 0 			# empty string
  	li a1, 0
  	j 4f
2:	la a0, inpstr
	lb t0, 0(a0)
	li t1, '-'
	bne t0, t1, 3f
	addi a0, a0, 1
3:	call str2fp
	# check if it was negative
	la t0, inpstr
	lb t0, 0(t0)
	li t1, '-'
	bne t0, t1, 4f
	call fpneg
4: 	lw ra, 0(sp)
  	addi sp, sp, 4
  	ret

.section .data
inpstr: .dcb.b 32


.ifdef TESTS
.section .text

# macro to create a Fixed point constant params are:
# integer part fractional part, decimal places (10 == .1, 100 = 0.01, etc)
.macro FPCONST HW LW PREC
	li a0, (\LW * (1<<32)) / \PREC
	li a1, \HW
.endm
# FPCONST 1 1234 10000  # for 1.1234

.globl test_fp
test_fp:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	call uart_init

	FPCONST 1 1234 10000
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl

	li a0, 0x1999999A
	li a1, 0
	call uart_printfp
	call uart_printnl

	li a0, 0
	li a1, 1234
	call uart_printfp
	call uart_printnl

	li a0, 0x80000000
	li a1, 1234
	call uart_printfp
	call uart_printnl

	# 3.14159265
	li a0, 0x243F6A79
	li a1, 0x00000003
	call uart_printfp
	call uart_printnl

	# -3.14159265
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	call uart_printfp
	call uart_printnl

	# -1
	li a0, 0x00000000
	li a1, 0xFFFFFFFF
	call uart_printfp
	call uart_printnl

	# -123.456 -> 123.456
	li a0, 0x8B439582
	li a1, 0xFFFFFF84
	call fpabs
	call uart_printfp
	call uart_printnl

	# 0.273
	li a0, 0x45E353F8
	li a1, 0
	call uart_printfp
	call uart_printnl

	# 0.785398163 PI/4
	li a0, 0xC90FDAA2
	li a1, 0
	call uart_printfp
	call uart_printnl

	# 0.273 * 100 == 27.3
	li a0, 0x45E353F8
	li a1, 0
	li a2, 0
	li a3, 100
	call fpmul
	call uart_printfp
	call uart_printnl

	# 0.01 * 10 = 0.1 = 0x00000000_1999999A
	li a0, 0x028F5C29
	li a1, 0
	li a2, 0
	li a3, 10
	call fpmul
	call uart_printfp
	call uart_printnl

	# 0.1 / 10 = 0.01 = 0x00000000_028F5C29
	li a0, 0x1999999A
	li a1, 0
	li a2, 0
	li a3, 10
	call fpdiv
	call uart_printfp
	call uart_printnl


	# 0 - 3.14159265 == -3.14159265
	li a0, 0
	li a1, 0
	li a2, 0x243F6A79
	li a3, 0x00000003
	call fpsub
	call uart_printfp
	call uart_printnl

	# -3.14159265 + 3.14159265 == 0
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	li a2, 0x243F6A79
	li a3, 0x00000003
	call fpadd
	call uart_printfp
	call uart_printnl

	# neg 3.141592 == -3.141592
	li a0, 0x243F6A79
	li a1, 0x00000003
	call fpneg
	call uart_printfp
	call uart_printnl

	# neg -3.141592 == 3.141592
	li a0, 0xDBC09587
	li a1, 0xFFFFFFFC
	call fpneg
	call uart_printfp
	call uart_printnl

	# 0.1 / 1.0028 == 0.099720781 0x00000000_19874D18
	li a0, 0x19999999
	li a1, 0
	li a2, 0x00B78034
	li a3, 1
	call fpdiv
	call uart_printfp
	call uart_printnl

	# result == 0.0997
	li a0, 0x19999999
	li a1, 0
	li a2, 0
	li a3, 1
	call fp_atan2
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl


1: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret

.globl test_read_fp
test_read_fp:
1:	call uart_getfp
	call uart_printfphex
	call uart_printspc
	call uart_printfp
	call uart_printnl
	j 1b
.endif
