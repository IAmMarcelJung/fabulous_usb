import serial
from modules import log

# Define special 4-byte acknowledgment sequence
ACK_SEQUENCE = b"\xfa\xb0\xfa\xbf"


def transmit_bitstream_serial(bitstream, port, baudrate=115200):
    with serial.Serial(port, baudrate, timeout=5) as ser:
        ser.write(bitstream)
        log.logger.success(f"Bitstream transmitted!")


def transmit_bitstream_serial_and_check_response(bitstream, port, baudrate=115200):
    with serial.Serial(port, baudrate, timeout=5) as ser:
        ser.write(bitstream)
        log.logger.success(f"Bitstream transmitted!")
        # Wait for a 4-byte response
        response = ser.read(4)
        if response == ACK_SEQUENCE:
            log.logger.success(
                f"Received expected acknowledgment: 0x{response.hex().upper()}"
            )
        elif len(response) == 4:
            log.logger.error(
                f"Received unexpected acknowledgment: 0x{response.hex().upper()}"
            )
            exit(1)
        else:
            log.logger.error("No acknowledgment received or response incomplete.")
            exit(1)


if __name__ == "__main__":
    pass
