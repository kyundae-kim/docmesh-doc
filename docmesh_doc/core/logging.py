import logging
import sys


def setup_logging(level: int):
    logging.basicConfig(
        level=level,
        format="%(levelname)s: %(asctime)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)]
    )
