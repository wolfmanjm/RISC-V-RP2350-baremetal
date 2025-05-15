This is a collection of bare metal, assembly code only access to the risc-v on
the RP2350 (pico2 or other)

This does not use any c code or the pico-sdk, although most of the registers
accesses are gleaned from looking at how the pico-sdk accesses low level H/W.

The code is in the src directory one header is in the top level directory
(the interrupt numbers).

The build is done using Rake and by looking at the Rakefile you can see how to
build the stuff, if Rake is not your thing.

As of now the code links into RAM for ease of development using the gdb load
command, I will add a linker script to allow loading from flash in the
future.

I use the assembler in corev-openhw-gcc-ubuntu2204-20240530, but pretty much
any recent risc-v assembler will work, presuming it supports the Hazard-3
instruction set.

src/startup.s does the initial setup and sets the clocks to run at 150mHz,
then after the setup calls main in main.s. which currently calls the test
routine that is being worked on.

Currently we have gpio, multicore, timers, ticks, uart, spi1, pwm, ili9341,
rotary and some blink examples. gpio interrupts with a test that uses a
rotary encoder is also included. One test in PWM is one that can be used to
terst an ESC and uses the encoder to increase or decrease the duty cycle, and
displays it on the TFT display.

I am particularly happy about the multicore as this is modelled after the
pico-sdk but far less complicated. You simply pass in the address where you
want core2 to run, the stack for core2 and call the routine. I have not
tested if interrupts work when running on the second core yet.

In general this decomplicates a lot of what the pico-sdk does, at the expense
of no error checking and only using a simplified set of functions.


Some more info here http://blog.wolfman.com/articles/2025/3/23/bare-metal-gpio-twiddling-for-risc-v-on-rpi-pico2

