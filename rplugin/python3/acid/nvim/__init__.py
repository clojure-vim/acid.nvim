import os
import binascii
import itertools
import tempfile
import zipfile
import glob
import sys
import re
from importlib.machinery import SourceFileLoader
from acid import pure
from acid.nvim.log import log_debug, log_warning


def convert_case(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()


def get_customization_variable(nvim, var, default=None):
    return nvim.current.buffer.vars.get(var, nvim.vars.get(var, default))


def find_clojure_fn(nvim, fname):
    rtp = nvim.options.get('runtimepath', '').split(',')

    if not rtp:
        return

    src = os.path.join('rplugin/python3/acid/clj_fns/', fname)

    for path in rtp:
        partial = os.path.join(path, src)
        if os.path.exists(partial):
            return partial


def find_extensions(nvim, source):
    """Search for base.py or *.py

    Searches $VIMRUNTIME/*/rplugin/python3/acid/$source[s]/
    """
    rtp = nvim.options.get('runtimepath', '').split(',')

    if not rtp:
        return

    sources = (
        os.path.join('rplugin/python3/acid', source, '*.py'),
    )

    for src in sources:
        for path in rtp:
            yield from glob.iglob(os.path.join(path, src))


def import_extensions(path, source, classname):
    """Import Acid plugin source class.

    If the class exists, add its directory to sys.path.
    """
    name = os.path.splitext(os.path.basename(path))[0]
    module_name = 'acid.%s.%s' % (source, name)
    module = SourceFileLoader(module_name, path).load_module()
    cls = getattr(module, classname, None)

    if not cls:
        return None

    dirname = os.path.dirname(path)

    if dirname not in sys.path:
        sys.path.insert(0, dirname)

    return cls


def current_file(nvim):
    return nvim.funcs.expand("%:p")


def current_path(nvim):
    return nvim.funcs.getcwd()


def path_to_ns(nvim):
    return pure.path_to_ns(nvim.funcs.expand("%:p:r"))

def get_port_no(nvim):
    pwd = current_path(nvim)

    with open(os.path.join(pwd, ".nrepl-port")) as port:
        return port.read().strip()


def repl_host_address(nvim):
    host = nvim.vars.get('acid_lein_host', '127.0.0.1')
    try:
        return [host, get_port_no(nvim)]
    except:
        return None


# Renamed the function, keeping this here to avoid breaking stuff..
localhost = repl_host_address


def formatted_localhost_address(nvim):
    addr = repl_host_address(nvim)
    if addr:
        return "{}://{}:{}".format('nrepl', *addr)
    else:
        return None


def get_acid_ns(nvim):
    strategy = get_customization_variable(nvim, 'acid_ns_strategy', 'buffer')
    if strategy == 'buffer':
        return path_to_ns(nvim)
    elif 'ns:' in strategy:
        return strategy.split(':')[-1]


def find_file_in_path(nvim, msg):
    fname = msg['file']
    protocol, *_, fpath = fname.split(':')

    if protocol == 'file':
        if os.path.exists(fpath):
            return fpath
        elif 'resource' in msg:
            resource = msg['resource']
            alt_paths = nvim.vars.get('acid_alt_paths', [])
            alt_test_paths = nvim.vars.get('acid_alt_test_paths', [])
            paths = ['src', 'test', *alt_paths, *alt_test_paths]

            for path in paths:
                attempt = os.path.join(path, resource)
                if os.path.exists(attempt):
                    return attempt

            project = resource.split('/')[0]
            foreign_project_fpath = nvim.vars.get('acid_project_root', None)

            if foreign_project_fpath is None:
                return

            for path in paths:
                attempt = os.path.join(
                    foreign_project_fpath, project, path, resource
                )
                if os.path.exists(attempt):
                    return attempt
    elif protocol == 'jar':
        jarpath, fpath = fpath.split('!')
        hashed = '{:X}'.format(
            binascii.crc32(bytes(jarpath, 'ascii')) & 0xffffffff
        )
        tmppath = os.path.join(tempfile.gettempdir(), hashed)

        if not os.path.exists(tmppath):
            os.mkdir(tmppath)
            zipf = zipfile.ZipFile(jarpath)
            zipf.extractall(tmppath)
            zipf.close()

        fpath = fpath if not os.path.isabs(fpath) else fpath[1:]
        full = os.path.join(tmppath, fpath)
        nvim.command('echom "{}"'.format(str([full, fpath, tmppath, jarpath])))
        if os.path.exists(full):
            return full

    return None
