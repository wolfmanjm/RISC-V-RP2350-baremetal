#include <stdio.h>
#include <stdlib.h>

#define uint unsigned int

uint spi_set_baudrate(uint baudrate) {
    uint freq_in = 150000000;
    uint prescale, postdiv;

    // Find smallest prescale value which puts output frequency in range of
    // post-divide. Prescale is an even number from 2 to 254 inclusive.
    for (prescale = 2; prescale <= 254; prescale += 2) {
        if (freq_in < (prescale + 2) * 256 * (unsigned long long) baudrate)
            break;
    }
    printf("prescale = %d\n", prescale);

    // Find largest post-divide which makes output <= baudrate. Post-divide is
    // an integer in the range 1 to 256 inclusive.
    for (postdiv = 256; postdiv > 1; --postdiv) {
        if (freq_in / (prescale * (postdiv - 1)) > baudrate)
            break;
    }
    printf("postdiv = %d\n", postdiv);

    // Return the frequency we were able to achieve
    return freq_in / (prescale * postdiv);
}



int main(int argc, char const *argv[])
{
    uint baudrate = atoi(argv[1]);
    uint i = spi_set_baudrate(baudrate);
    printf("requested =  %d, actual baudrate= %d\n", baudrate, i);
    return 0;
}
