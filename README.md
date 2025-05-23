This is a collection of bare metal, assembly code only access to the risc-v on
the RP2350 (pico2 or other)

This does not use any c code or the pico-sdk, although most of the registers
accesses are gleaned from looking at how the pico-sdk accesses low level H/W.

The code is in the src directory one header is in the top level directory
(the interrupt numbers).

The build is done using Rake and by looking at the Rakefile you can see how to
build the stuff, if Rake is not your thing.

By default the code links into RAM for ease of development using the gdb load
command, by Editing the LDFLAGS line in the Rakefile you can compile for
FLASH, and FLASH it using the gdb load command. (I will add uf2 creation at
some point).

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
* rotary encoder
* some blink examples
* gpio interrupts with a test that uses a rotary encoder

Also a test in PWM is one that can be used to test an ESC and uses the encoder
to increase or decrease the duty cycle, and displays it on the TFT display.

There is also a S31.32 fixed point library that handles

* add
* sub
* div
* mul
* abs
* neg
* atan2

plus uart print versions to print out fixed point numbers as decimal.

Double word math:

* div32s and div32u 64bit / 32bit divides
* mul64_div (a*b)/c where the intermediate a*b is kept as 64 bit with 32 but result



In general this decomplicates a lot of what the pico-sdk does, at the expense
of no error checking and only using a simplified set of functions.


Some more info here http://blog.wolfman.com/articles/2025/3/23/bare-metal-gpio-twiddling-for-risc-v-on-rpi-pico2

