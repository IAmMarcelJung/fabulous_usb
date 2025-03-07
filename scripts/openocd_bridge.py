#!/usr/bin/env python3
import socket
import serial
import modules.log as log


# Constants
HOST = "127.0.0.1"
PORT = 4567
SERIAL_PORT = "/dev/ttyACM0"
BAUDRATE = 115200
TIMEOUT = 0.1


def setup_serial():
    """Initialize and return a USB CDC serial connection."""
    return serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)


def setup_server():
    """Initialize and return a TCP server socket."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((HOST, PORT))
    sock.listen(1)
    print(f"Listening on {HOST}:{PORT} for OpenOCD bitbang connections...")
    return sock


def handle_bitbang_command(ser, cmd):
    """Send ASCII command directly as bytes to the JTAG bridge."""
    ser.write(cmd.encode())  # Send ASCII as a byte
    if cmd == "R":  # Only read when TDO is requested
        return ser.read(1)
    return b""


def handle_client(conn, ser):
    """Process commands from an OpenOCD client over TCP."""
    try:
        while True:
            data = conn.recv(1024)  # Read up to 1024 bytes
            if not data:
                log.logger.warning("Client disconnected.")
                break  # Exit loop and wait for a new client

            log.logger.info(f"Received {data}")
            response = b"".join(
                [handle_bitbang_command(ser, chr(byte)) for byte in data]
            )
            if response:
                log.logger.info(f"Sending {response}")
                conn.sendall(response)

    except ConnectionResetError:
        log.logger.warning("Client forcefully disconnected.")
    finally:
        conn.close()


def main():
    """Main function to start the server and manage connections."""
    log.setup_logger(0)
    ser = setup_serial()
    sock = setup_server()

    try:
        while True:
            print("Waiting for a new connection...")
            conn, addr = sock.accept()
            print(f"Connected to OpenOCD: {addr}")
            handle_client(conn, ser)  # Handle client interaction

    except KeyboardInterrupt:
        print("\nServer shutting down...")

    finally:
        sock.close()
        ser.close()


if __name__ == "__main__":
    main()
