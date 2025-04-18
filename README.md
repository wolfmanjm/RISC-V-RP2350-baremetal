This is a collection of bare metal, assembly code only access to the risc-v on
the RP2350 (pico2 or other)

This does not use any c code or the pico-sdk, although most of the registers
accesses are gleaned from looking at how the pico-sdk accesses low level H/W.


The code is in the src directory one header is in the top level directory (the interrupt numbers).

The build is done using Rake and by looking at the Rakefile you can see how to
build the stuff, if Rake is not your thing.

I use the assembler in corev-openhw-gcc-ubuntu2204-20240530, but pretty much
any recent risc-v assembler will work, presuming it supports the Hazard-3
instruction set.

src/startup.s does the initial setup and sets the clocks to run at 150mHz,
then after the setup calls main in main.s.

Currently we have gpio, multicore, timers, ticks, uart and some blink examples.

I am particularly happy about the multicore as this is modelled after the pico-sdk but far less complicated.
You simply pass in the address where you want core2 to run, the stack for core2 and call the routine.

I general this decomplicates a lot of what the pico-sdk does, at the expense of no error checking and only usign a simplified set of functions.

spi is not yet completed.



