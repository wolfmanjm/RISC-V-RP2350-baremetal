import math


def calculate_pwm_settings(target_freq, sys_clock=150_000_000, max_top=65535):
    """
    Calculate suitable (DIV, TOP) settings for PWM on the RP2040.

    Parameters:
        target_freq (float): Desired PWM frequency in Hz.
        sys_clock (float): System clock frequency in Hz. Default is 125 MHz.
        max_top (int): Maximum allowed TOP value. Default is 65535.

    Returns:
        List of tuples (DIV, TOP, resolution_bits)
    """
    results = []
    for top in range(1, max_top + 1):
        div = sys_clock / (target_freq * (top + 1))
        if 1.0 <= div <= 255.996:
            resolution_bits = top.bit_length()
            results.append((round(div, 6), top, resolution_bits))

    return results


# Example usage:
if __name__ == "__main__":
    target_freq = 4000  # 100 Hz
    settings = calculate_pwm_settings(target_freq)

    if not settings:
        print("No valid settings found for the given frequency.")
    else:
        # Sort by resolution (highest first)
        best = sorted(settings, key=lambda x: x[2], reverse=True)[0]
        print(f"Best setting for {target_freq} Hz:")
        div = best[0] + (0.5 / (1 << 4))  # round to the nearest fraction
        idiv = math.trunc(div * (1 << 4))
        # c->div = (((uint)div_int) << 4) | (((uint)div_frac4) << 0);
        print(f"  DIV = {best[0]} (div={div}, idiv=0x{idiv:04X})")
        print(f"  TOP = {best[1]}")
        print(f"  Resolution = {best[2]} bits")

        # Uncomment to print all possible configurations
        if False:
            for div, top, bits in settings:
                print(f"DIV: {div:.6f}, TOP: {top}, Resolution: {bits} bits")
