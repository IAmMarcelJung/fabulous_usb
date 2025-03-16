#!/usr/bin/env python3
import socket
import serial
import modules.log as log
from modules.argument_parser import parse_bridge_arguments

# Configuration defaults, can be overridden by command line arguments
HOST = "127.0.0.1"
PORT = 4567
SERIAL_PORT = "/dev/ttyACM2"


class JTAGServer:
    """TCP Server that forwards OpenOCD bitbang commands to a USB CDC serial JTAG bridge."""

    def __init__(
        self,
        host=HOST,
        port=PORT,
        serial_port=SERIAL_PORT
    ):
        self.host = host
        self.port = port
        self.serial_port = serial_port
        self.ser = None
        self.sock = None

    def setup_serial(self):
        """Initialize USB CDC serial connection."""
        try:
            self.ser = serial.Serial(
                self.serial_port, timeout=5,baudrate=115200
            )
            log.logger.info(
                f"Connected to serial port {self.serial_port}."
            )
        except serial.SerialException as e:
            log.logger.error(f"Failed to open serial port: {e}")
            raise

    def setup_server(self):
        """Initialize TCP server socket."""
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.bind((self.host, self.port))
            self.sock.listen(1)
            log.logger.info(
                f"Listening on {self.host}:{self.port} for OpenOCD bitbang connections..."
            )
        except socket.error as e:
            log.logger.error(f"Failed to set up server: {e}")
            raise

    def handle_bitbang_command(self, cmd):
        """Process and send an ASCII command to the JTAG bridge."""

        # Don't do anything if a quit request was received
        if cmd != "Q":
            ascii_byte = cmd.encode()
            log.logger.debug(
                f"Sending {cmd} to the device"
            )

            try:
                if not self.ser.is_open:
                    self.ser.open()
                self.ser.write(ascii_byte)  # Send command over serial
            except serial.SerialException as e:
                log.logger.error(f"Error writing to serial: {e}")
                return b""

            if cmd == "R":  # Only read when TDO is requested
                tdo = self.ser.read(1)
                log.logger.debug(f"Read tdo data {tdo.decode("utf-8")} from device.")
                return tdo

            if self.ser.is_open:
                self.ser.close()
        return b""

    def handle_client(self, conn):
        """Process commands from an OpenOCD client over TCP."""
        try:
            while True:
                # Always receive one byte at a time
                data = conn.recv(1)
                if not data:
                    log.logger.warning("Client disconnected.")
                    break  # Exit loop

                log.logger.debug(f"Received {data.decode("utf-8")} from the client")

                response = self.handle_bitbang_command(chr(data[0])) # data will just be one byte

                if response:
                    log.logger.debug(f"Sending {response.decode("utf-8")} to the client")
                    conn.sendall(response)

                if (
                    b"Q" in data
                ):  # If "Q" is received, close connection but keep server running
                    log.logger.info("Received 'Q' - Closing current client connection.")
                    break

        except ConnectionResetError:
            log.logger.warning("Client forcefully disconnected.")
        finally:
            conn.close()

    def start(self):
        """Start the JTAG server."""
        self.setup_serial()
        self.setup_server()

        try:
            while True:
                log.logger.info("Waiting for a new connection...")
                conn, addr = self.sock.accept()
                log.logger.info(f"Connected to client at: {addr}")
                self.handle_client(conn)

        except KeyboardInterrupt:
            log.logger.info("\nServer shutting down due to keyboard interrupt.")

        finally:
            self.cleanup()

    def cleanup(self):
        """Cleanup resources on shutdown."""
        log.logger.info("Closing server and serial connection...")
        if self.sock:
            self.sock.close()
        if self.ser:
            self.ser.close()
        log.logger.info("Server stopped cleanly.")


if __name__ == "__main__":
    args = parse_bridge_arguments()
    log.setup_logger(args.verbose)
    server = JTAGServer(args.address, args.port, args.acm_port)
    server.start()
