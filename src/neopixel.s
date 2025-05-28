# - One is indicated by: .8us high, .45us low
# - Zero is indicated by: .4us high, .85us low
# 24 bits followed by 50us low, RGB 888
# high bit first sent as GRB

.equ NEOPIXEL_PIN, 16
delay800ns:
	csrr t1, mcycle		# each cycle is 6.6ns
	addi t0, t1, 121-17	# 121 cycles is about 800ns
1:	csrr t1, mcycle
	bltu t1, t0, 1b
	ret
delay850ns:
	csrr t1, mcycle		# each cycle is 6.6ns
	addi t0, t1, 99		# 128 cycles is about 850ns
1:	csrr t1, mcycle
	bltu t1, t0, 1b
	ret
delay450ns:
	csrr t1, mcycle		# each cycle is 6.6ns
	addi t0, t1, 41		# 68 cycles is about 450ns
1:	csrr t1, mcycle
	bltu t1, t0, 1b
	ret
delay400ns:
	csrr t1, mcycle		# each cycle is 6.6ns
	addi t0, t1, 45		# 60 cycles is about 400ns
1:	csrr t1, mcycle
	bltu t1, t0, 1b
	ret

np_one:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li a0, NEOPIXEL_PIN
	call pin_high
	call delay800ns
	call pin_low
	call delay450ns

  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

np_zero:
	addi sp, sp, -4
  	sw ra, 0(sp)

	li a0, NEOPIXEL_PIN
	call pin_high
	call delay400ns
	call pin_low
	call delay850ns

 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# send 24bits in a0
np_send:
	addi sp, sp, -4
  	sw ra, 0(sp)
	mv t3, a0
	li t2, 23
1:	bext t4, t3, t2
	beqz t4, 2f
	call np_one
	j 3f
2:	call np_zero
3:	addi t2, t2, -1
	bgez t2, 1b
 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# a0 r a1 g a2 b
np_rgb:
	addi sp, sp, -4
  	sw ra, 0(sp)
	slli t0, a1, 16
	slli t1, a0, 8
	or t0, t0, t1
	or t0, t0, a2
	mv a0, t0
	call np_send

 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

np_reset:
	addi sp, sp, -4
  	sw ra, 0(sp)
	# reset pulse
	li a0, NEOPIXEL_PIN
	call pin_low
	li a0, 100
	call delayus
 	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

.globl test_neopixel
test_neopixel:
	li a0, NEOPIXEL_PIN
	call pin_output
	li a0, NEOPIXEL_PIN
	call pin_low

	# test timing
1:  j 2f
	call np_one
	call np_zero
	j 1b

# test rgb
2: 	li a0, 255
	li a1, 0
	li a2, 0
	call np_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 0
 	li a1, 255
 	li a2, 0
	call np_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 0
	li a1, 0
 	li a2, 255
	call np_rgb
	call np_reset
	li a0, 1000
	call delayms
 	li a0, 255
	li a1, 255
 	li a2, 255
	call np_rgb
	call np_reset
	li a0, 1000
	call delayms
	j 2b
