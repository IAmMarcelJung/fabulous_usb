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


def display_footer(start_time, total_bytes):
    end_time = time.time()
    total_time = end_time - start_time
    logger.info(f"Transmitted {total_bytes} bytes in {total_time:.4f} seconds")
    logger.info(
        f"Approximate transmission rate: {total_bytes/total_time:.2f} bytes/second"
    )


if __name__ == "__main__":
    pass
