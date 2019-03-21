import logging
import inspect

fh = logging.FileHandler('/tmp/acid-log-handler.log')
fh.setLevel(logging.DEBUG)

if fh.formatter is None:
    formatter = logging.Formatter(
        '%(asctime)s - [%(name)s :%(levelname)s] - %(message)s'
    )
    fh.setFormatter(formatter)

def _log(frame):
    name = inspect.getmodule(frame[0]).__name__
    logger = logging.getLogger(name)
    logger.propagate = False

    if not len(logger.handlers):
        logger.addHandler(fh)
        logger.setLevel(logging.DEBUG)

    return logger

def log_debug(message, *args):
    message = message.format(*args) if len(args) > 0 else message
    _log(inspect.stack()[1]).debug(message)

def log_info(message, *args):
    message = message.format(*args) if len(args) > 0 else message
    _log(inspect.stack()[1]).info(message)

def log_warning(message, *args):
    message = message.format(*args) if len(args) > 0 else message
    _log(inspect.stack()[1]).warning(message)

def log_error(message, *args):
    message = message.format(*args) if len(args) > 0 else message
    _log(inspect.stack()[1]).error(message)
