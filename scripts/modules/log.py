import sys
import time
from loguru import logger


def setup_logger(verbosity: int):
    # Remove the default logger to avoid duplicate logs
    logger.remove()
    logger.level("INFO", color="<white>")

    # Define logger format
    if verbosity >= 2:
        log_format = (
            "[<level>{level:}</level>]: "
            "<cyan>[{time:DD-MM-YYYY HH:mm:ss]}</cyan> | "
            "<green>[{name}</green>:<green>{function}</green>:<green>{line}]</green> - "
            "<level>{message}</level>"
        )
        level = "DEBUG"
    elif verbosity == 1:
        log_format = "[<level>{level:}</level>]: " "<level>{message}</level>"
        level = "DEBUG"

    else:
        log_format = "[<level>{level:}</level>]: " "<level>{message}</level>"
        level = "INFO"

    # Add logger to write logs to stdout
    logger.add(sys.stdout, format=log_format, level=level, colorize=True)


# def display_footer(start_time, total_bytes):
#     end_time = time.time()
#     total_time = end_time - start_time
#     logger.debug(f"Transmitted {total_bytes} bytes in {total_time:.4f} seconds")
#     logger.debug(
#         f"Approximate transmission rate: {total_bytes/total_time:.2f} bytes/second"
#     )


def display_footer(start_time, total_bytes):
    end_time = time.time()
    total_time = end_time - start_time
    if total_time == 0:
        logger.warning("Total time is too short to calculate a meaningful rate.")
        return

    bytes_per_second = total_bytes / total_time
    kilobytes_per_second = bytes_per_second / 1024
    kilobits_per_second = (bytes_per_second * 8) / 1000  # Using 1000 for kbit

    logger.debug(f"Transmitted {total_bytes} bytes in {total_time:.4f} seconds")
    logger.debug(f"Approximate transmission rate: {bytes_per_second:.2f} bytes/second")
    logger.debug(f"Approximate transmission rate: {kilobytes_per_second:.2f} KB/s")
    logger.debug(f"Approximate transmission rate: {kilobits_per_second:.2f} kbit/s")


if __name__ == "__main__":
    pass
