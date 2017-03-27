import logging
import inspect

fh = logging.FileHandler('/tmp/acid-log-handler.log')
fh.setLevel(logging.DEBUG)

if fh.formatter is None:
    formatter = logging.Formatter(
        '%(asctime)s - [%(name)s :%(levelname)s] - %(message)s'
    )
    fh.setFormatter(formatter)

def _log(frame, fn):
    name = inspect.getmodule(frame[0]).__name__
    logger = logging.getLogger(name)
    if not len(logger.handlers):
        logger.addHandler(fh)
        logger.setLevel(logging.DEBUG)

    fn(logger)

def log_debug(message, name=None):
    _log(name or inspect.stack()[1], lambda log: log.debug(message))

def log_info(message, name=None):
    _log(name or inspect.stack()[1], lambda log: log.info(message))

def log_warning(message, name=None):
    _log(name or inspect.stack()[1], lambda log: log.warning(message))

def log_error(message, name=None):
    _log(name or inspect.stack()[1], lambda log: log.error(message))


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
    log_error(message, inspect.stack()[1])

def warning(nvim, message):
    echo_warning(nvim, message)
    log_warning(message, inspect.stack()[1])

def info(nvim, message):
    echo(nvim, message)
    log_info(message, inspect.stack()[1])
