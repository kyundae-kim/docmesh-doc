from fastapi_template.core import logging
from fastapi_template.core.config import LoggingConfig, LoggingLevel


def setup_logging(config: LoggingConfig):
    '''Configure logging based on provided configuration.
    
    Args:
        config: LoggingConfig object with logging settings
    '''

    if not isinstance(config.level, LoggingLevel):
        raise ValueError(f"Invalid logging level: {config.level}")

    if config.level == LoggingLevel.DEBUG:
        level = logging.logging.DEBUG
    elif config.level == LoggingLevel.INFO:
        level = logging.logging.INFO
    elif config.level == LoggingLevel.WARNING:
        level = logging.logging.WARNING
    else:
        level = logging.logging.DEBUG

    logging.setup_logging(level)
