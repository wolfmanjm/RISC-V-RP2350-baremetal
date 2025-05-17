.equ I2C0_BASE, 0x40090000
.equ I2C1_BASE, 0x40098000
  .equ _IC_CON, 0x00000000
    .equ b_IC_CON_MASTER_MODE, 1<<0
    .equ m_IC_CON_SPEED, 0x00000006
    .equ o_IC_CON_SPEED, 1
    .equ b_IC_CON_IC_10BITADDR_SLAVE, 1<<3
    .equ b_IC_CON_IC_10BITADDR_MASTER, 1<<4
    .equ b_IC_CON_IC_RESTART_EN, 1<<5
    .equ b_IC_CON_IC_SLAVE_DISABLE, 1<<6
    .equ b_IC_CON_STOP_DET_IFADDRESSED, 1<<7
    .equ b_IC_CON_TX_EMPTY_CTRL, 1<<8
    .equ b_IC_CON_RX_FIFO_FULL_HLD_CTRL, 1<<9
    .equ b_IC_CON_STOP_DET_IF_MASTER_ACTIVE, 1<<10
  .equ _IC_TAR, 0x00000004
    .equ m_IC_TAR_IC_TAR, 0x000003FF
    .equ o_IC_TAR_IC_TAR, 0
    .equ b_IC_TAR_GC_OR_START, 1<<10
    .equ b_IC_TAR_SPECIAL, 1<<11
  .equ _IC_SAR, 0x00000008
    .equ m_IC_SAR_IC_SAR, 0x000003FF
    .equ o_IC_SAR_IC_SAR, 0
  .equ _IC_DATA_CMD, 0x00000010
    .equ m_IC_DATA_CMD_DAT, 0x000000FF
    .equ o_IC_DATA_CMD_DAT, 0
    .equ b_IC_DATA_CMD_CMD, 1<<8
    .equ b_IC_DATA_CMD_STOP, 1<<9
    .equ b_IC_DATA_CMD_RESTART, 1<<10
    .equ b_IC_DATA_CMD_FIRST_DATA_BYTE, 1<<11
  .equ _IC_SS_SCL_HCNT, 0x00000014
    .equ m_IC_SS_SCL_HCNT_IC_SS_SCL_HCNT, 0x0000FFFF
    .equ o_IC_SS_SCL_HCNT_IC_SS_SCL_HCNT, 0
  .equ _IC_SS_SCL_LCNT, 0x00000018
    .equ m_IC_SS_SCL_LCNT_IC_SS_SCL_LCNT, 0x0000FFFF
    .equ o_IC_SS_SCL_LCNT_IC_SS_SCL_LCNT, 0
  .equ _IC_FS_SCL_HCNT, 0x0000001c
    .equ m_IC_FS_SCL_HCNT_IC_FS_SCL_HCNT, 0x0000FFFF
    .equ o_IC_FS_SCL_HCNT_IC_FS_SCL_HCNT, 0
  .equ _IC_FS_SCL_LCNT, 0x00000020
    .equ m_IC_FS_SCL_LCNT_IC_FS_SCL_LCNT, 0x0000FFFF
    .equ o_IC_FS_SCL_LCNT_IC_FS_SCL_LCNT, 0
  .equ _IC_INTR_STAT, 0x0000002c
    .equ b_IC_INTR_STAT_R_RX_UNDER, 1<<0
    .equ b_IC_INTR_STAT_R_RX_OVER, 1<<1
    .equ b_IC_INTR_STAT_R_RX_FULL, 1<<2
    .equ b_IC_INTR_STAT_R_TX_OVER, 1<<3
    .equ b_IC_INTR_STAT_R_TX_EMPTY, 1<<4
    .equ b_IC_INTR_STAT_R_RD_REQ, 1<<5
    .equ b_IC_INTR_STAT_R_TX_ABRT, 1<<6
    .equ b_IC_INTR_STAT_R_RX_DONE, 1<<7
    .equ b_IC_INTR_STAT_R_ACTIVITY, 1<<8
    .equ b_IC_INTR_STAT_R_STOP_DET, 1<<9
    .equ b_IC_INTR_STAT_R_START_DET, 1<<10
    .equ b_IC_INTR_STAT_R_GEN_CALL, 1<<11
    .equ b_IC_INTR_STAT_R_RESTART_DET, 1<<12
  .equ _IC_INTR_MASK, 0x00000030
    .equ b_IC_INTR_MASK_M_RX_UNDER, 1<<0
    .equ b_IC_INTR_MASK_M_RX_OVER, 1<<1
    .equ b_IC_INTR_MASK_M_RX_FULL, 1<<2
    .equ b_IC_INTR_MASK_M_TX_OVER, 1<<3
    .equ b_IC_INTR_MASK_M_TX_EMPTY, 1<<4
    .equ b_IC_INTR_MASK_M_RD_REQ, 1<<5
    .equ b_IC_INTR_MASK_M_TX_ABRT, 1<<6
    .equ b_IC_INTR_MASK_M_RX_DONE, 1<<7
    .equ b_IC_INTR_MASK_M_ACTIVITY, 1<<8
    .equ b_IC_INTR_MASK_M_STOP_DET, 1<<9
    .equ b_IC_INTR_MASK_M_START_DET, 1<<10
    .equ b_IC_INTR_MASK_M_GEN_CALL, 1<<11
    .equ b_IC_INTR_MASK_M_RESTART_DET, 1<<12
  .equ _IC_RAW_INTR_STAT, 0x00000034
    .equ b_IC_RAW_INTR_STAT_RX_UNDER, 1<<0
    .equ b_IC_RAW_INTR_STAT_RX_OVER, 1<<1
    .equ b_IC_RAW_INTR_STAT_RX_FULL, 1<<2
    .equ b_IC_RAW_INTR_STAT_TX_OVER, 1<<3
    .equ b_IC_RAW_INTR_STAT_TX_EMPTY, 1<<4
    .equ b_IC_RAW_INTR_STAT_RD_REQ, 1<<5
    .equ b_IC_RAW_INTR_STAT_TX_ABRT, 1<<6
    .equ b_IC_RAW_INTR_STAT_RX_DONE, 1<<7
    .equ b_IC_RAW_INTR_STAT_ACTIVITY, 1<<8
    .equ b_IC_RAW_INTR_STAT_STOP_DET, 1<<9
    .equ b_IC_RAW_INTR_STAT_START_DET, 1<<10
    .equ b_IC_RAW_INTR_STAT_GEN_CALL, 1<<11
    .equ b_IC_RAW_INTR_STAT_RESTART_DET, 1<<12
  .equ _IC_RX_TL, 0x00000038
    .equ m_IC_RX_TL_RX_TL, 0x000000FF
    .equ o_IC_RX_TL_RX_TL, 0
  .equ _IC_TX_TL, 0x0000003c
    .equ m_IC_TX_TL_TX_TL, 0x000000FF
    .equ o_IC_TX_TL_TX_TL, 0
  .equ _IC_CLR_INTR, 0x00000040
    .equ b_IC_CLR_INTR_CLR_INTR, 1<<0
  .equ _IC_CLR_RX_UNDER, 0x00000044
    .equ b_IC_CLR_RX_UNDER_CLR_RX_UNDER, 1<<0
  .equ _IC_CLR_RX_OVER, 0x00000048
    .equ b_IC_CLR_RX_OVER_CLR_RX_OVER, 1<<0
  .equ _IC_CLR_TX_OVER, 0x0000004c
    .equ b_IC_CLR_TX_OVER_CLR_TX_OVER, 1<<0
  .equ _IC_CLR_RD_REQ, 0x00000050
    .equ b_IC_CLR_RD_REQ_CLR_RD_REQ, 1<<0
  .equ _IC_CLR_TX_ABRT, 0x00000054
    .equ b_IC_CLR_TX_ABRT_CLR_TX_ABRT, 1<<0
  .equ _IC_CLR_RX_DONE, 0x00000058
    .equ b_IC_CLR_RX_DONE_CLR_RX_DONE, 1<<0
  .equ _IC_CLR_ACTIVITY, 0x0000005c
    .equ b_IC_CLR_ACTIVITY_CLR_ACTIVITY, 1<<0
  .equ _IC_CLR_STOP_DET, 0x00000060
    .equ b_IC_CLR_STOP_DET_CLR_STOP_DET, 1<<0
  .equ _IC_CLR_START_DET, 0x00000064
    .equ b_IC_CLR_START_DET_CLR_START_DET, 1<<0
  .equ _IC_CLR_GEN_CALL, 0x00000068
    .equ b_IC_CLR_GEN_CALL_CLR_GEN_CALL, 1<<0
  .equ _IC_ENABLE, 0x0000006c
    .equ b_IC_ENABLE_ENABLE, 1<<0
    .equ b_IC_ENABLE_ABORT, 1<<1
    .equ b_IC_ENABLE_TX_CMD_BLOCK, 1<<2
  .equ _IC_STATUS, 0x00000070
    .equ b_IC_STATUS_ACTIVITY, 1<<0
    .equ b_IC_STATUS_TFNF, 1<<1
    .equ b_IC_STATUS_TFE, 1<<2
    .equ b_IC_STATUS_RFNE, 1<<3
    .equ b_IC_STATUS_RFF, 1<<4
    .equ b_IC_STATUS_MST_ACTIVITY, 1<<5
    .equ b_IC_STATUS_SLV_ACTIVITY, 1<<6
  .equ _IC_TXFLR, 0x00000074
    .equ m_IC_TXFLR_TXFLR, 0x0000001F
    .equ o_IC_TXFLR_TXFLR, 0
  .equ _IC_RXFLR, 0x00000078
    .equ m_IC_RXFLR_RXFLR, 0x0000001F
    .equ o_IC_RXFLR_RXFLR, 0
  .equ _IC_SDA_HOLD, 0x0000007c
    .equ m_IC_SDA_HOLD_IC_SDA_TX_HOLD, 0x0000FFFF
    .equ o_IC_SDA_HOLD_IC_SDA_TX_HOLD, 0
    .equ m_IC_SDA_HOLD_IC_SDA_RX_HOLD, 0x00FF0000
    .equ o_IC_SDA_HOLD_IC_SDA_RX_HOLD, 16
  .equ _IC_TX_ABRT_SOURCE, 0x00000080
    .equ b_IC_TX_ABRT_SOURCE_ABRT_7B_ADDR_NOACK, 1<<0
    .equ b_IC_TX_ABRT_SOURCE_ABRT_10ADDR1_NOACK, 1<<1
    .equ b_IC_TX_ABRT_SOURCE_ABRT_10ADDR2_NOACK, 1<<2
    .equ b_IC_TX_ABRT_SOURCE_ABRT_TXDATA_NOACK, 1<<3
    .equ b_IC_TX_ABRT_SOURCE_ABRT_GCALL_NOACK, 1<<4
    .equ b_IC_TX_ABRT_SOURCE_ABRT_GCALL_READ, 1<<5
    .equ b_IC_TX_ABRT_SOURCE_ABRT_HS_ACKDET, 1<<6
    .equ b_IC_TX_ABRT_SOURCE_ABRT_SBYTE_ACKDET, 1<<7
    .equ b_IC_TX_ABRT_SOURCE_ABRT_HS_NORSTRT, 1<<8
    .equ b_IC_TX_ABRT_SOURCE_ABRT_SBYTE_NORSTRT, 1<<9
    .equ b_IC_TX_ABRT_SOURCE_ABRT_10B_RD_NORSTRT, 1<<10
    .equ b_IC_TX_ABRT_SOURCE_ABRT_MASTER_DIS, 1<<11
    .equ b_IC_TX_ABRT_SOURCE_ARB_LOST, 1<<12
    .equ b_IC_TX_ABRT_SOURCE_ABRT_SLVFLUSH_TXFIFO, 1<<13
    .equ b_IC_TX_ABRT_SOURCE_ABRT_SLV_ARBLOST, 1<<14
    .equ b_IC_TX_ABRT_SOURCE_ABRT_SLVRD_INTX, 1<<15
    .equ b_IC_TX_ABRT_SOURCE_ABRT_USER_ABRT, 1<<16
    .equ m_IC_TX_ABRT_SOURCE_TX_FLUSH_CNT, 0xFF800000
    .equ o_IC_TX_ABRT_SOURCE_TX_FLUSH_CNT, 23
  .equ _IC_SLV_DATA_NACK_ONLY, 0x00000084
    .equ b_IC_SLV_DATA_NACK_ONLY_NACK, 1<<0
  .equ _IC_DMA_CR, 0x00000088
    .equ b_IC_DMA_CR_RDMAE, 1<<0
    .equ b_IC_DMA_CR_TDMAE, 1<<1
  .equ _IC_DMA_TDLR, 0x0000008c
    .equ m_IC_DMA_TDLR_DMATDL, 0x0000000F
    .equ o_IC_DMA_TDLR_DMATDL, 0
  .equ _IC_DMA_RDLR, 0x00000090
    .equ m_IC_DMA_RDLR_DMARDL, 0x0000000F
    .equ o_IC_DMA_RDLR_DMARDL, 0
  .equ _IC_SDA_SETUP, 0x00000094
    .equ m_IC_SDA_SETUP_SDA_SETUP, 0x000000FF
    .equ o_IC_SDA_SETUP_SDA_SETUP, 0
  .equ _IC_ACK_GENERAL_CALL, 0x00000098
    .equ b_IC_ACK_GENERAL_CALL_ACK_GEN_CALL, 1<<0
  .equ _IC_ENABLE_STATUS, 0x0000009c
    .equ b_IC_ENABLE_STATUS_IC_EN, 1<<0
    .equ b_IC_ENABLE_STATUS_SLV_DISABLED_WHILE_BUSY, 1<<1
    .equ b_IC_ENABLE_STATUS_SLV_RX_DATA_LOST, 1<<2
  .equ _IC_FS_SPKLEN, 0x000000a0
    .equ m_IC_FS_SPKLEN_IC_FS_SPKLEN, 0x000000FF
    .equ o_IC_FS_SPKLEN_IC_FS_SPKLEN, 0
  .equ _IC_CLR_RESTART_DET, 0x000000a8
    .equ b_IC_CLR_RESTART_DET_CLR_RESTART_DET, 1<<0
  .equ _IC_COMP_PARAM_1, 0x000000f4
    .equ m_IC_COMP_PARAM_1_APB_DATA_WIDTH, 0x00000003
    .equ o_IC_COMP_PARAM_1_APB_DATA_WIDTH, 0
    .equ m_IC_COMP_PARAM_1_MAX_SPEED_MODE, 0x0000000C
    .equ o_IC_COMP_PARAM_1_MAX_SPEED_MODE, 2
    .equ b_IC_COMP_PARAM_1_HC_COUNT_VALUES, 1<<4
    .equ b_IC_COMP_PARAM_1_INTR_IO, 1<<5
    .equ b_IC_COMP_PARAM_1_HAS_DMA, 1<<6
    .equ b_IC_COMP_PARAM_1_ADD_ENCODED_PARAMS, 1<<7
    .equ m_IC_COMP_PARAM_1_RX_BUFFER_DEPTH, 0x0000FF00
    .equ o_IC_COMP_PARAM_1_RX_BUFFER_DEPTH, 8
    .equ m_IC_COMP_PARAM_1_TX_BUFFER_DEPTH, 0x00FF0000
    .equ o_IC_COMP_PARAM_1_TX_BUFFER_DEPTH, 16
  .equ _IC_COMP_VERSION, 0x000000f8
    .equ m_IC_COMP_VERSION_IC_COMP_VERSION, 0xFFFFFFFF
    .equ o_IC_COMP_VERSION_IC_COMP_VERSION, 0
  .equ _IC_COMP_TYPE, 0x000000fc
    .equ m_IC_COMP_TYPE_IC_COMP_TYPE, 0xFFFFFFFF
    .equ o_IC_COMP_TYPE_IC_COMP_TYPE, 0

.equ IC_CON_SPEED_VALUE_FAST, 0x2

.equ RESETS_BASE, 0x40020000
	.equ _RESETS_RESET, 0x000
	.equ _RESETS_RESET_DONE, 0x008
		.equ b_RESET_DONE_I2C0, 1<<4
		.equ b_RESET_DONE_I2C1, 1<<5

.equ GPIO_FUNC_I2C, 3

.equ WRITE_NORMAL, (0x0000)   # Normal read write access
.equ WRITE_XOR   , (0x1000)   # Atomic XOR on write
.equ WRITE_SET   , (0x2000)   # Atomic bitmask set on write
.equ WRITE_CLR   , (0x3000)   # Atomic bitmask clear on write

# change these as desired
.equ I2CX_BASE, I2C0_BASE
.equ I2C_SDA_PIN, 4
.equ I2C_SCL_PIN, 5

# for baudrate: 500000
.equ FS_SCL_HCNT, 0x00000078
.equ FS_SCL_LCNT, 0x000000B4
.equ FS_SPKLEN, 0x0000000B
.equ SDA_HOLD_COUNT, 0x0000002E

.section .text

# reset i2c in a0
i2c_reset:
	li t1, RESETS_BASE
	sw a0, _RESETS_RESET(t1)
	sw zero, _RESETS_RESET(t1)
1:	lw t2, _RESETS_RESET_DONE(t1)		# RESETS_RESET_DONE
	and t2, t2, a0
	beqz t2, 1b
	ret

# a0 = 1 enable b_IC_ENABLE_ENABLE
i2c_enable:
    li t0, I2CX_BASE
    sw a0, _IC_ENABLE(t0)
    ret

.globl i2c_init
i2c_init:
	addi sp, sp, -4
  	sw ra, 0(sp)

	# we reset both as not sure which one we will be using
	li a0, b_RESET_DONE_I2C0
	call i2c_reset
	li a0, b_RESET_DONE_I2C1
	call i2c_reset

	li a0, 0
    call i2c_enable

	# set pins 4, 5 - SDA, SCL
  	li a0, I2C_SCL_PIN
  	li a1, GPIO_FUNC_I2C
  	call gpio_set_function
  	li a0, I2C_SDA_PIN
  	li a1, GPIO_FUNC_I2C
  	call gpio_set_function

  	li a0, I2C_SCL_PIN
    call gpio_set_pullup
  	li a0, I2C_SDA_PIN
    call gpio_set_pullup

    # Configure as a fast-mode master with RepStart support, 7-bit addresses
    li t0, I2CX_BASE
    li t1, (IC_CON_SPEED_VALUE_FAST<<o_IC_CON_SPEED)&m_IC_CON_SPEED | b_IC_CON_MASTER_MODE | b_IC_CON_IC_SLAVE_DISABLE | b_IC_CON_IC_RESTART_EN | b_IC_CON_TX_EMPTY_CTRL
    sw t1, _IC_CON(t0)

    sw zero, _IC_RX_TL(t0)
    sw zero, _IC_TX_TL(t0)

    # set baudrate
    li t1, FS_SCL_HCNT
    sw t1, _IC_FS_SCL_HCNT(t0)
    li t1, FS_SCL_LCNT
    sw t1, _IC_FS_SCL_LCNT(t0)
    li t1, FS_SPKLEN
    sw t1, _IC_FS_SPKLEN(t0)

	lw t1, _IC_SDA_HOLD(t0)
	li t2, ~(m_IC_SDA_HOLD_IC_SDA_TX_HOLD)
	and t1, t1, t2
	li t2, (SDA_HOLD_COUNT)<<o_IC_SDA_HOLD_IC_SDA_TX_HOLD
	or t1, t1, t2
	sw t1, _IC_SDA_HOLD(t0)

    li a0, 1
    call i2c_enable

  	lw ra, 0(sp)
  	addi sp, sp, 4
	ret

# read from i2c address in a0, to buffer in a1, with n bytes of data in a2
# return error code in a0, where 0 is OK
.globl i2c_read
i2c_read:
	li t0, I2CX_BASE
	sw zero, _IC_ENABLE(t0)
	sw a0, _IC_TAR(t0)
	li t1, b_IC_ENABLE_ENABLE
	sw t1, _IC_ENABLE(t0)

	# check write available
1:	lw t1, _IC_TXFLR(t0)
	li t2, 16
	sub t1, t2, t1
	beqz t1, 1b

	li t1, b_IC_DATA_CMD_CMD
	sw t1, _IC_DATA_CMD(t0)

2:	lw t1, _IC_RAW_INTR_STAT(t0)
	andi t1, t1, b_IC_RAW_INTR_STAT_TX_ABRT
	bnez t1, read_abort
	lw t1, _IC_RXFLR(t0)
	beqz t1, 2b

	# read data
	lb t1, _IC_DATA_CMD(t0)
	sb t1, 0(a1)
	addi a1, a1, 1
	addi a2, a2, -1
	bnez a2, 1b
	# done
	li a0, 0
	ret


read_abort:
	lw t1, _IC_TX_ABRT_SOURCE(t0)
	lw t2, _IC_CLR_TX_ABRT(t0)
	li a0, 1
	ret

.globl i2c_scan
i2c_scan:
	addi sp, sp, -8
  	sw ra, 0(sp)
  	sw s1, 4(sp)

	call i2c_init

	li s1, 0
1:	mv a0, s1
	# check not reserved addr: (addr & 0x78) == 0 || (addr & 0x78) == 0x78;
	andi t1, a0, 0x78
	beqz t1, 2f
	li t2, 0x78
	beq t1, t2, 2f

	la a1, tbuf
	li a2, 1
	call i2c_read
	bnez a1, no_addr
	# got something at this addr, print the address in hex
	mv a0, s1
	la a1, tbuf
	call parse_2h
	la a0, tbuf
	call uart_puts
	li a0, ' '
	call uart_putc
	j 2f
no_addr:
	# nothing at this address

2:	addi s1, s1, 1
	li t1, 127
	bne s1, t1, 1b

	# done
  	lw ra, 0(sp)
  	lw s1, 4(sp)
  	addi sp, sp, 8
	ret

.section .data
tbuf: .byte 0, 0, 0, 0
