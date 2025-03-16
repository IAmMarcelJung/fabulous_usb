import argparse


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Transmit bitstream to a serial device."
    )
    parser.add_argument(
        "protocol",
        type=str,
        choices=["USB", "Bitbang", "BitbangMPSSE", "UART", "JTAG"],
        help="The protocol to use: USB, Bitbang, UART, JTAG.",
    )
    parser.add_argument(
        "--baudrate",
        type=int,
        default=115200,
        help="The baud rate to use, defaults to 115200.",
    )
    parser.add_argument(
        "--acm_port",
        type=str,
        default="/dev/ttyACM0",
        help="The ACM port to use when using USB directly, defaults to /dev/ttyACM0.",
    )
    parser.add_argument(
        "--ftdi_port",
        type=str,
        default="/dev/ttyUSB0",
        help="The USB port to use when using an FTDI adapter, defaults to /dev/ttyUSB0",
    )
    parser.add_argument(
        "file", type=str, help="The path to the bitstream file to transmit."
    )
    parser.add_argument(
        "-v",
        "--verbose",
        default=False,
        action="count",
        help="Show detailed log information including function and line number",
    )
    return parser.parse_args()

def parse_bridge_arguments():
    parser = argparse.ArgumentParser(
        description="Create a server which acts as a bridge between OpenOCD and the JTAG target device can connect."
    )
    parser.add_argument(
        "--acm_port",
        type=str,
        default="/dev/ttyACM2",
        help="The ACM port to for transmitting the JTAG bitbang data, defaults to /dev/ttyACM2.",
    )
    parser.add_argument(
        "--address",
        type=str,
        default="127.0.0.1",
        help="The address of the bridge server, defaults to 127.0.0.1."
    )
    parser.add_argument(
        "--port",
        type=int,
        default=4567,
        help="The port of the bridge server, defaults to 4567."
    )
    parser.add_argument(
        "-v",
        "--verbose",
        default=False,
        action="count",
        help="Show detailed log information including function and line number",
    )
    return parser.parse_args()

if __name__ == "__main__":
    pass
