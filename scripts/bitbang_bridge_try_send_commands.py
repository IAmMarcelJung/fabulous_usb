#!/usr/bin/env python3
import socket
import time
import modules.log as log


class JTAGClient:
    """Handles connection to the OpenOCD bitbang server over TCP."""

    def __init__(self, host="127.0.0.1", port=4567):
        self.host = host
        self.port = port
        self.sock = None
        self._connect()

    def _connect(self):
        """Establish a TCP connection."""
        try:
            self.sock = socket.create_connection((self.host, self.port))
            log.logger.info(f"Connected to {self.host}:{self.port}")
        except Exception as e:
            log.logger.error(f"Failed to connect: {e}")
            self.sock = None
            exit(1)

    def send_commands(self, commands):
        """Send a list of ASCII commands over the socket connection."""
        if not self.sock:
            log.logger.error("No active connection!")
            return

        for cmd in commands:
            log.logger.info(f"Sending: {cmd}")
            try:
                self.sock.sendall(cmd.encode())
                time.sleep(0.1)
            except Exception as e:
                log.logger.error(f"Error sending command '{cmd}': {e}")

    def close(self):
        """Ensure 'Q' is sent before closing the socket."""
        if self.sock:
            try:
                log.logger.info("Sending quit command: Q")
                self.sock.sendall(b"Q")
                self.sock.close()
            except Exception as e:
                log.logger.error(f"Error closing socket: {e}")
            finally:
                self.sock = None
            log.logger.info("Connection closed cleanly.")

    def __del__(self):
        """Ensure cleanup when the object is deleted."""
        self.close()


def main():
    log.setup_logger(0)

    # Create JTAG client
    jtag = JTAGClient()

    # Send commands
    # jtag.send_commands(
    #     ["B", "b", "B", "b", "B", "b", "B", "1", "2", "3", "4", "5", "6", "7"]
    # )

    # Toggle TDI
    for _ in range(5):
        jtag.send_commands(["0", "1"])

    # Toggle TCK
    for _ in range(5):
        jtag.send_commands(["0", "4"])

    # Toggle TMS
    for _ in range(5):
        jtag.send_commands(["0", "2"])

    # Toggle All
    for _ in range(5):
        jtag.send_commands(["0", "7"])

    # Toggle TRST
    for _ in range(5):
        jtag.send_commands(["r", "t"])

    # Toggle SRST
    for _ in range(5):
        jtag.send_commands(["r", "s"])


if __name__ == "__main__":
    main()
