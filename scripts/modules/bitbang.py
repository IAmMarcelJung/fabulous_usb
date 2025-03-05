#!/usr/bin/env python3

from pyftdi.gpio import GpioController

BITS_IN_BYTE = 8
BITS_IN_WORD = 32
BYTES_IN_WORD = BITS_IN_WORD // BITS_IN_BYTE


class Bitbang:
    def __init__(self, url: str = "ftdi://ftdi:232h/1"):
        """Initialize the FTDI GPIO interface.

        :param url: The FTDI device URL, default is "ftdi://ftdi:232h/1".
        """
        self.gpio = GpioController()
        self.SDATA_PIN = 0x20  # D5
        self.SCLK_PIN = 0x40  # D6
        self.gpio.open_from_url(url, direction=self.SDATA_PIN + self.SCLK_PIN)
        self.gpio.set_direction(
            self.SDATA_PIN | self.SCLK_PIN, self.SDATA_PIN | self.SCLK_PIN
        )

    def transmit(self, data: bytes, ctrl_word: int) -> None:
        """Transmit data using a custom bitbang protocol.

        :param data: The data to be transmitted.
        :param ctrl_word: The control word to be used for the transmission.
        """
        self._set_clk_low()
        for byte_pos, byte in enumerate(data):
            for bit_pos in range(BITS_IN_BYTE):
                bit = (byte >> ((BITS_IN_BYTE - 1) - bit_pos)) & 0x1
                self._write_sdata(bit)
                self._set_clk_high()
                ctrl_bit = (
                    ctrl_word
                    >> (
                        (BITS_IN_WORD - 1)
                        - (BITS_IN_BYTE * (byte_pos % BYTES_IN_WORD) + bit_pos)
                    )
                ) & 0x1
                self._write_sdata(ctrl_bit)
                self._set_clk_low()

    def _write_sdata(self, value: int):
        """Write a value to the SDATA pin.

        :param value: The bit value to set (0 or 1).
        """
        if value:
            self.gpio.write(self.gpio.read() | self.SDATA_PIN)
        else:
            self.gpio.write(self.gpio.read() & ~self.SDATA_PIN)

    def _set_clk_low(self):
        """Set clock signal to low."""
        self.gpio.write(self.gpio.read() & ~self.SCLK_PIN)

    def _set_clk_high(self):
        """Set clock signal to high."""
        self.gpio.write(self.gpio.read() | self.SCLK_PIN)

    def close(self):
        """Close the FTDI connection."""
        self.gpio.close()


if __name__ == "__main__":
    bitbang = Bitbang()
    try:
        test_data = b"\xaa\x55"  # Example test pattern
        control_word = 0xDEADBEEF
        bitbang.transmit(test_data, control_word)
    finally:
        bitbang.close()
