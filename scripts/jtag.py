#!/usr/bin/env python3
import argparse
from pathlib import Path

import ftdi
from ftdi import JTAG, Instruction


def read_binary_file(file_path):
    """
    Read a binary file completely.

    Args:
        file_path (Path): Path to the binary file

    Returns:
        bytes: The binary file contents
    """
    try:
        return file_path.read_bytes()
    except FileNotFoundError:
        raise FileNotFoundError(f"Error: File '{file_path}' does not exist")
    except IOError as e:
        raise IOError(f"Error reading file: {e}")


def parse_args():
    """Parse command line arguments in a pythonic way."""
    parser = argparse.ArgumentParser(
        description="Script to upload a bitstream file using JTAG over an FTDI adapter."
    )
    parser.add_argument(
        "file",
        type=Path,  # Using Path type is more pythonic
        help="Path to the bistream file to read.",
    )
    return parser.parse_args()


def main():
    """Main entry point of the program."""
    args = parse_args()

    try:
        binary_data = read_binary_file(args.file)
        print(f"Read '{args.file}'")
    except (FileNotFoundError, IOError) as e:
        print(e)
        return 1

    jtag_i = JTAG()
    print("PRELOAD, 00111010")
    jtag_i.load_and_exec(Instruction.PRELOAD, "00111010")
    print("EXTEST, 00000000")
    jtag_i.load_and_exec(Instruction.EXTEST, "00000000")
    print("IDCODE")
    jtag_i.load_and_exec(Instruction.IDCODE, Instruction.IDCODE.name)
    print("INTEST, 11000101")
    jtag_i.load_and_exec(Instruction.INTEST, "11000101")
    print("BYPASS, 00111010")
    jtag_i.load_and_exec(Instruction.BYPASS, "00111010")

    jtag_i.load_config(binary_data)
    print("1 sec timer starting now")
    jtag_i.clock_for(1)
    print("timer ended")

    return 0


if __name__ == "__main__":
    exit(main())
