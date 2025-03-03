#!/usr/bin/env python3
import serial
import argparse


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Transmit bitstream to a serial device."
    )
    parser.add_argument(
        "port", type=str, help="The serial port to use (e.g., /dev/ttyACM0)."
    )
    parser.add_argument(
        "--baudrate",
        type=int,
        default=115200,
        help="The baud rate to use, defaults to 115200.",
    )
    parser.add_argument(
        "file", type=str, help="The path to the bitstream file to transmit."
    )
    return parser.parse_args()


def transmit_bitstream(port, baudrate, file_path):
    with open(file_path, "rb") as f:
        bitstream = f.read()
        end_of_bitstream = 0x12345678.to_bytes(4, byteorder="big")
        end_of_bitstream = end_of_bitstream + 0x0.to_bytes(4, byteorder="big")
        bitstream = bitstream + end_of_bitstream
        # total_bytes = len(bitstream) + len(end_of_bitstream)
        total_bytes = len(bitstream)

    with serial.Serial(port, baudrate) as ser:
        ser.write(bitstream)
        # ser.write(end_of_bitstream)

    print(f"Bitstream transmitted! Total bytes transmitted: {total_bytes}")


def main():
    args = parse_arguments()
    transmit_bitstream(args.port, args.baudrate, args.file)


if __name__ == "__main__":
    main()
