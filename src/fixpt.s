# attempt to do s31.32 fixed point arithmetic for risc-v
# with help from chatgpt

# 32-bit signed integer multiplication returning 64-bit product
#   arguments:
#       a0: x
#       a1: y
#   return:
#       a0: x*y lower 32 bits
#       a1: x*y upper 32 bits
#
mul_signed_full:
    mulh    t0, a1, a0
    mul     a0, a1, a0
    mv      a1, t0
    ret

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
    # a_lo * b_lo
    mul     t0, a0, a2         # t0 = low 32 bits
    mulhu   t1, a0, a2         # t1 = high 32 bits

    # a_hi * b_lo
    mul     t2, a1, a2

    # a_lo * b_hi
    mul     t3, a0, a3

    # t2 + t3 + t1 (middle 64 bits)
    add     t4, t2, t3
    add     t4, t4, t1         # t4 = middle 32 bits after combining

    # a_hi * b_hi (not needed unless doing 128-bit result)
    # mul     t5, a1, a3       # optional

    # Now assemble the result:
    # 128-bit result = [hi64 | lo64] = (t4 << 32) | (t0 >> 0)

    # Right shift full 128-bit result by 32:
    # result = (middle << 0) | (lo >> 32)
    mv      a0, t4             # lower 32 bits of result
    srl     a1, t4, 31         # sign-extend if needed (optional)

    ret

# Output:
# a0 = result low 32 bits (S31.32)
# a1 = result high 32 bits (S31.32)
#
# Signature (RV32 ABI):
#   a1:a0 = numerator (signed S31.32)
#   a3:a2 = denominator (signed S31.32)
# Returns:
#   a1:a0 = quotient (signed S31.32)
#
.globl fpdiv
fpdiv:

    # 1) Build 96‑bit numerator = (num << 32)
    mv      t0, x0        # t0 = num_low  = 0
    mv      t1, a0        # t1 = num_mid  = original low
    mv      t2, a1        # t2 = num_hi   = original high

    # 2) Extract and save input signs
    srai    a4, a1, 31    # a4 = sign_num (0 or –1)
    srai    a5, a3, 31    # a5 = sign_den

    # 3) Absolute‑value the 96‑bit numerator in [t2:t1:t0]
    #    (bitwise invert if sign=–1, then add 1 with proper carry propagation)
    xor     t2, t2, a4
    xor     t1, t1, a4
    xor     t0, t0, a4
    add     t0, t0, a4
    sltu    t5, t0, a4     # carry from low
    add     t1, t1, t5
    sltu    t5, t1, t5     # carry from mid
    add     t2, t2, t5

    # 4) Absolute‑value the 64‑bit denominator in [a3:a2]
    xor     a3, a3, a5
    xor     a2, a2, a5
    add     a2, a2, a5
    sltu    t5, a2, a5     # carry into high
    add     a3, a3, t5

    # 5) Prepare quotient = 0
    mv      t3, x0        # t3 = quot_hi
    mv      t4, x0        # t4 = quot_lo

    # 6) Long‐division loop for 96 ÷ 64
    li      a6, 64        # bit‑count

div_loop:
    # 6a) shift numerator left by 1: [t2:t1:t0] <<= 1
    sll     t2, t2, 1
    srl     t5, t1, 31
    or      t2, t2, t5
    sll     t1, t1, 1
    srl     t5, t0, 31
    or      t1, t1, t5
    sll     t0, t0, 1

    # 6b) shift quotient left by 1: [t3:t4] <<= 1
    sll     t3, t3, 1
    srl     t5, t4, 31
    or      t3, t3, t5
    sll     t4, t4, 1

    # 6c) if numerator ≥ denominator then subtract & set low‐bit
    bgtu    t2, a3,  div_sub
    bltu    t2, a3,  div_skip
    bgeu    t1, a2,  div_sub
    j       div_skip

div_sub:
    sub     t1, t1, a2
    sltu    t5, t1, a2     # borrow from mid?
    sub     t2, t2, a3
    sub     t2, t2, t5     # propagate borrow into high
    ori     t4, t4, 1      # set quotient’s low bit

div_skip:
    addi    a6, a6, -1
    bnez    a6, div_loop

    # 7) Restore sign: if (sign_num ^ sign_den) < 0, negate quotient
    xor     t5, a4, a5
    beqz    t5, done

    # 7a) 64‑bit two’s‑complement negation of [t3:t4]
    not     t4, t4
    not     t3, t3
    addi    t4, t4, 1
    sltu    t5, t4, x0     # carry
    add     t3, t3, t5

done:
    # 8) Return quotient in a1:a0
    mv      a0, t3
    mv      a1, t4
    ret

# Inputs:
#   a0 = lhs low 32 bits
#   a1 = lhs high 32 bits
#   a2 = rhs low 32 bits
#   a3 = rhs high 32 bits
# Output:
#   a0 = result low 32 bits
#   a1 = result high 32 bits
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
.globl fpsub
fpsub:
    sltu t0, a0, a2       # Set t0 = 1 if a borrow will occur (a0 < a2)
    sub  a0, a0, a2       # Subtract lower 32 bits: a0 = a0 - a2
    sub  a1, a1, a3       # Subtract upper 32 bits
    sub  a1, a1, t0       # Subtract borrow from upper 32 bits
    ret

# negate fp number in a0/a1
fpneg:
    not a0, a0          # Invert lower 32 bits
    not a1, a1          # Invert upper 32 bits
    addi a0, a0, 1      # Add 1 to lower half
    # Check if there was a carry (a0 became zero after addition)
    seqz t0, a0         # t0 = 1 if a0 == 0 (i.e., carry occurred)
    add a1, a1, t0      # Add carry to upper half
    ret

# Input: a1:a0 = y (S31.32), a3:a2 = x (S31.32)
# Output: a1:a0 = atan2(y, x) (S31.32)
.globl fp_atan2
fp_atan2:
	addi sp, sp, -16
  	sw ra, 0(sp)
  	sw s1, 4(sp)
	sw s2, 8(sp)
  	sw s3, 12(sp)

    # Save signs
    srai    t0, a1, 31     # t0 = sign_y
    srai    t1, a3, 31     # t1 = sign_x

    # --- Special case: x == 0 ---
    or      t2, a2, a3
    bnez    t2, do_div

    # If y > 0 → return π/2
    # If y < 0 → return -π/2
    li      t3, 0x1921FB54     # π/2 low
    li      t4, 0x00000000     # π/2 high
    li      t5, 0xE6DE04AC     # -π/2 low
    li      t6, 0xFFFFFFFF     # -π/2 high
    bltz    a1, return_neg_pi_2
    mv      a0, t3
    mv      a1, t4
    j atan2done
return_neg_pi_2:
    mv      a0, t5
    mv      a1, t6
    j atan2done

do_div:
    # Call fixed_div_s31_32(y, x)
    # Inputs: a1:a0 (y), a3:a2 (x)
    # Result: a1:a0 = z = y / x
    call    fpdiv

    # Save z in s2:s1
    mv      s2, a0
    mv      s1, a1

    # abs(z)
    srai    t2, a1, 31     # sign_z
    xor     a0, a0, t2
    xor     a1, a1, t2
    add     a0, a0, t2
    sltu    t3, a0, t2
    add     a1, a1, t3

    # Compute 1 - |z|
    li      t4, 0xFFFFFFFF     # 1.0 in S31.32
    li      t5, 0x00000000
    sub     a0, t4, a0
    sub     a1, t5, a1
    sltu    t3, t4, a0
    sub     a1, a1, t3

    # Multiply by 0.273 (S31.32)
    li      t6, 0x0458B2D7     # 0.273 low
    li      s3, 0x00000000     # 0.273 high
    # multiply a1:a0 × s3:t6 → result in a1:a0
    # Reuse your fixed-point multiply routine here
    mv      a2, t6
    mv      a3, s3
    call    fpmul   # must return a1:a0

    # Add π/4
    li      t2, 0x0C90FDBA     # π/4 low
    li      t3, 0x00000000     # π/4 high
    add     a0, a0, t2
    sltu    t4, a0, t2
    add     a1, a1, t3
    add     a1, a1, t4

    # Multiply by original z (s1:s2)
    mv      a2, s2
    mv      a3, s1
    call    fpmul   # a1:a0 = atan(z)

    # Apply correction for quadrant
    bltz    a3, apply_pi_correction
    j atan2done

apply_pi_correction:
    bltz    s1, sub_pi         # z was negative → θ = θ - π
    # θ = θ + π
    li      t2, 0x3243F6A8
    li      t3, 0x00000000
    add     a0, a0, t2
    sltu    t4, a0, t2
    add     a1, a1, t3
    add     a1, a1, t4
    j atan2done

sub_pi:
    li      t2, 0x3243F6A8
    li      t3, 0x00000000
    sub     a0, a0, t2
    sltu    t4, a0, t2
    sub     a1, a1, t3
    sub     a1, a1, t4

atan2done:
  	lw ra, 0(sp)
  	lw s1, 4(sp)
 	lw s2, 8(sp)
  	lw s3, 12(sp)
  	addi sp, sp, 16
    ret

#
# test above
#

# print fixed point number in hex a0 Lower, a1 Upper
uart_printfphex:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	mv s1, a0
	mv a0, a1
	call uart_print8hex
	li a0, '_'
	call uart_putc
	mv a0, s1
	call uart_print8hex

  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret


.globl uart_printfp
# Arguments:
#   a0 = lower 32 bits fractional part
#   a1 = upper 32 bits integer part
# Prints:
#   S31.32 value as signed decimal to uart_putc (with 6 digits after decimal)
uart_printfp:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

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
  	addi sp, sp, 8
    ret


.globl test_fp
test_fp:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	call uart_init
	li a0, 0x028F5C29
	li a1, 0
	call uart_printfphex
	li a0, ':'
	call uart_putc
	li a0, 0x028F5C29
	li a1, 0
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

1: 	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret
