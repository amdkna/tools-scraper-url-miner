import logging
import logging.config
from pathlib import Path


class LoggerFactory:
    """
    LoggerFactory reads configuration from an INI file (config/logging.ini) if present,
    otherwise falls back to a basic console configuration.
    Usage:
        from url_miner.logger import get_logger
        logger = get_logger(__name__)
    """

    _configured = False

    @classmethod
    def configure(cls, config_path: Path | str | None = None) -> None:
        """
        Configure the logging subsystem once. If `config_path` is provided and exists,
        loads fileConfig; otherwise, uses a basicConfig default.
        """
        if cls._configured:
            return

        if not config_path:
            # default: assume project root /config/logging.ini
            config_path = Path(__file__).parents[2] / "config" / "logging.ini"

        config_path = Path(config_path)
        if config_path.exists():
            logging.config.fileConfig(config_path, disable_existing_loggers=False)
        else:
            logging.basicConfig(
                level=logging.INFO,
                format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
            )

        cls._configured = True


def get_logger(name: str) -> logging.Logger:
    """
    Get a named logger, ensuring the logging system is configured.

    :param name: the logger name (usually __name__)
    :return: configured Logger instance
    """
    LoggerFactory.configure()
    return logging.getLogger(name)
