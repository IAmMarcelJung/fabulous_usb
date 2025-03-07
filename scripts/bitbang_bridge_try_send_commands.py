#!/usr/bin/env python3
import socket
import time
import modules.log as log

HOST = "127.0.0.1"
PORT = 4567


def send_commands(commands, host, port):
    with socket.create_connection((host, port)) as sock:
        for cmd in commands:
            log.logger.info(f"Sending: {cmd}")
            sock.sendall(cmd.encode())
            time.sleep(0.1)


def main():
    log.setup_logger(0)
    commands = ["B", "b", "B", "b", "B", "b", "B", "1", "2", "3", "4", "5", "6", "7"]
    send_commands(commands, HOST, PORT)


if __name__ == "__main__":
    main()
