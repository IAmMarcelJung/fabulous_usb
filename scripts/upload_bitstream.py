#!/usr/bin/env python3
import serial
import time
import modules.log as log
from modules.serial_transmission import (
    transmit_bitstream_serial,
    transmit_bitstream_serial_and_check_response,
)
from modules.bitbang import Bitbang
from modules.argument_parser import parse_arguments


def read_bitstream(file_path):
    with open(file_path, "rb") as f:
        bitstream = f.read()
        end_of_bitstream = 0x12345678.to_bytes(4, byteorder="big")
        end_of_bitstream = end_of_bitstream + 0x0.to_bytes(4, byteorder="big")
        end_of_bitstream = end_of_bitstream + 0x0.to_bytes(4, byteorder="big")
        end_of_bitstream = end_of_bitstream + 0x0.to_bytes(4, byteorder="big")
        bitstream = bitstream + end_of_bitstream
    return bitstream


# def transmit_config_jtag(bitstream):
#     jtag_i = JTAG()
#     log.logger.info("PRELOAD, 00111010")
#     jtag_i.load_and_exec(Instruction.PRELOAD, "00111010")
#     log.logger.info("EXTEST, 00000000")
#     jtag_i.load_and_exec(Instruction.EXTEST, "00000000")
#     log.logger.info("IDCODE")
#     jtag_i.load_and_exec(Instruction.IDCODE, Instruction.IDCODE.name)
#     log.logger.info("INTEST, 11000101")
#     jtag_i.load_and_exec(Instruction.INTEST, "11000101")
#     log.logger.info("BYPASS, 00111010")
#     jtag_i.load_and_exec(Instruction.BYPASS, "00111010")
#
#     jtag_i.load_config(bitstream)
#     log.logger.info("1 sec timer starting now")
#     jtag_i.clock_for(1)
#     log.logger.info("timer ended")


def main():
    args = parse_arguments()
    bitstream = read_bitstream(args.file)
    len_bitstream = len(bitstream)
    start_time = time.time()
    log.setup_logger(args.verbose)
    match (args.protocol):
        case "USB":
            try:
                transmit_bitstream_serial_and_check_response(
                    bitstream, args.acm_port, args.baudrate
                )
                log.display_footer(start_time, len_bitstream)
            except serial.SerialException:
                log.logger.error(
                    f"Could not access port {args.acm_port}."
                    + " Please use another port for the direct USB"
                    + "connection (set with --acm_port=<port>.)"
                )

        case "UART":
            try:
                transmit_bitstream_serial(bitstream, args.ftdi_port, args.baudrate)
                log.display_footer(start_time, len_bitstream)
            except serial.SerialException:
                log.logger.error(
                    f"Could not access port {args.ftdi_port}."
                    + " Please use another port for the FTDI based"
                    + "connection (set with --ftdi_port=<port>.)"
                )
        case "Bitbang":
            bitbang = Bitbang()
            try:
                control_word = 0xFAB1_FAB1
                bitbang.transmit(bitstream, control_word)
                log.logger.success(f"Bitstream transmitted!")
                log.display_footer(start_time, len_bitstream)
            finally:
                bitbang.close()
        case "JTAG":
            # import this locally so since this requires the correct FTDI
            # adapter
            from jtag import JTAG

            jtag = JTAG()
            jtag.load_config(list(bitstream))
        case _:
            log.logger.error(f"Protocl {args.protocol} is unknown")


if __name__ == "__main__":
    main()
