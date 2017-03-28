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

def echo(nvim, message):
    nvim.command('echom {}'.format(nvim.funcs.string(
        "Acid: {}".format(message)
    )))

def echo_error(nvim, message):
    nvim.command('echohl ErrorMsg')
    echo(nvim, message)
    nvim.command('echohl None')

def echo_warning(nvim, message):
    nvim.command('echohl WarningMsg')
    echo(nvim, message)
    nvim.command('echohl None')

def error(nvim, message):
    echo_error(nvim, message)
    log_error(message)

def warning(nvim, message):
    echo_warning(nvim, message)
    log_warning(message)

def info(nvim, message):
    echo(nvim, message)
    log_info(message)
