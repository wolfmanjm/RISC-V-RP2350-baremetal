import math

baudrate = 100_000
freq_in = 150_000_000

period = math.trunc((freq_in + baudrate / 2) / baudrate)
lcnt = math.trunc((period * 3) / 5)
hcnt = period - lcnt

assert(not (hcnt > 65535))
assert(not (lcnt > 65535))
assert(not (hcnt < 8))
assert(not (lcnt < 8))


if baudrate < 1000000:
    sda_tx_hold_count = math.trunc(((freq_in * 3) / 10000000) + 1)
else:
    sda_tx_hold_count = math.trunc(((freq_in * 3) / 25000000) + 1)

assert(sda_tx_hold_count <= lcnt - 2)

if lcnt < 16:
    spklcnt = 1
else:
    spklcnt = math.trunc(lcnt / 16)

print(f"for baudrate: {baudrate}")
print(f".equ FS_SCL_HCNT, 0x{hcnt:08X}")
print(f".equ FS_SCL_LCNT, 0x{lcnt:08X}")
print(f".equ FS_SPKLEN, 0x{spklcnt:08X}")
print(f".equ SDA_HOLD_COUNT, 0x{sda_tx_hold_count:08X}")

print(f"actual baudrate= {math.trunc(freq_in / period)}")
