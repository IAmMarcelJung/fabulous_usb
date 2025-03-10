#!/usr/bin/env python3
import socket
import serial
import modules.log as log

# Configuration Constants
HOST = "127.0.0.1"
PORT = 4567
SERIAL_PORT = "/dev/ttyACM0"
BAUDRATE = 115200
TIMEOUT = 0.1


class JTAGServer:
    """TCP Server that forwards OpenOCD bitbang commands to a USB CDC serial JTAG bridge."""

    def __init__(
        self,
        host=HOST,
        port=PORT,
        serial_port=SERIAL_PORT,
        baudrate=BAUDRATE,
        timeout=TIMEOUT,
    ):
        self.host = host
        self.port = port
        self.serial_port = serial_port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.sock = None

    def setup_serial(self):
        """Initialize USB CDC serial connection."""
        try:
            self.ser = serial.Serial(
                self.serial_port, self.baudrate, timeout=self.timeout
            )
            log.logger.info(
                f"Connected to serial port {self.serial_port} at {self.baudrate} baud."
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
        ascii_byte = cmd.encode()
        log.logger.debug(
            f"Sending '{cmd}' (byte: {int.from_bytes(ascii_byte, 'big'):08b})"
        )

        try:
            self.ser.write(ascii_byte)  # Send command over serial
        except serial.SerialException as e:
            log.logger.error(f"Error writing to serial: {e}")
            return b""

        if cmd == "R":  # Only read when TDO is requested
            return self.ser.read(1)
        return b""

    def handle_client(self, conn):
        """Process commands from an OpenOCD client over TCP."""
        try:
            while True:
                data = conn.recv(1024)  # Read up to 1024 bytes
                if not data:
                    log.logger.warning("Client disconnected.")
                    break  # Exit loop

                log.logger.info(f"Received: {data}")
                response = b"".join(
                    [self.handle_bitbang_command(chr(byte)) for byte in data]
                )

                if response:
                    log.logger.info(f"Sending: {response}")
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
        log.setup_logger(0)
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
    server = JTAGServer()
    server.start()
