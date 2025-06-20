This is a collection of bare metal, hand coded assembly for the risc-v on
the RP2350 (pico2 or other).

This does not use any c code or the pico-sdk, although most of the registers
accesses are gleaned from looking at how the pico-sdk accesses low level H/W.

The library code is in the libsrc directory, althoug a couple of headers are
in the top level directory(the interrupt numbers and fonts).

The appcode is in appsrc and you name the app you want to build on the
commandline eg `rake target=testmain` or `rake target=imu-angle`

The build is done using Rake and by looking at the Rakefile you can see how to
build the stuff, if Rake is not your thing.

By default the code links into RAM for ease of development using the gdb load
command, to link for FLASH use `rake flash=1` this will also create a .uf2
file for ease of flashing using drag and drop.


I use the assembler in corev-openhw-gcc-ubuntu2204-20240530, but pretty much
any recent risc-v assembler will work, presuming it supports the Hazard-3
instruction set.

src/startup.s does the initial setup and sets the clocks to run at 150mHz,
then after the setup calls main in main.s. which currently calls the test
routine that is being worked on.

Currently we have the following peripherals implemented...

* gpio
* multicore
* timers
* ticks
* uart
* spi1
* pwm
* ili9341
* i2c
* ADC
* rotary encoder
* bitbanged neopixel
* flash program and erase


There tends to be tests for each library source, however for ease of testing and development the
test you want to run is in testmain.s and you comment out the ones you do not want to run.

There are tests in the appsrc directory, some of these tests are...

* some blink examples
* gpio interrupts with a test that uses a rotary encoder
* a test in PWM that can be used to test an ESC and uses the encoder to
  increase or decrease the duty cycle, and displays it on the TFT display.

The uart library includes routines to convert numbers into strings and print integers, and hex
numbers, and read in characters and lines and numbers.

* uart_putc
* uart_puts
* uart_getc
* uart_gets
* uart_printn
* uart_printun
* uart_print2hex
* uart_print8hex
* uart_printnl
* uart_printspc
* uart_getint
* str2int
* int2str
* uint2str
* hex1_2str
* hex2_2str
* hex4_2str
* hex8_2str

There is also a S31.32 fixed point library that handles:

* fpadd
* fpsub
* fpdiv
* fpmul
* fpabs
* fpneg
* fp_atan2
* str2fp
* uart_printfphex
* fp2str
* uart_printfp
* uart_printfp1
* uart_getfp

NOTE uart print versions to print out fixed point numbers as decimal, and read
in fixed point numbers. Also convert a fixed point number to a string and print to 1DP.

Double word math:

* div32s and div32u 64bit / 32bit divides
* mul64_div (a * b)/c where the intermediate a * b is kept as 64 bit with 32 bit result
* dadd
* dsub
* dabs
* dneg
* mul_64_128u
* mul_32_64
* d_lshift
* d_rshift


*NOTE* most of these routines could be called from c as they conform to the
 ABI in most cases.

In general this decomplicates a lot of what the pico-sdk does, at the expense
of no error checking and only using a simplified set of functions.


Some more info here http://blog.wolfman.com/articles/2025/5/19/bare-metal-gpio-twiddling-for-risc-v-on-rpi-pico2

