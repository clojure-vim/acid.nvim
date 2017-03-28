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
    _log(inspect.stack()[1]).debug(message.format(*args))

def log_info(message, *args):
    _log(inspect.stack()[1]).info(message.format(*args))

def log_warning(message, *args):
    _log(inspect.stack()[1]).warning(message.format(*args))

def log_error(message, *args):
    _log(inspect.stack()[1]).error(message.format(*args))

def echo(nvim, message):
    nvim.command('echom "Acid: {}"'.format(nvim.funcs.string(message)))

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
