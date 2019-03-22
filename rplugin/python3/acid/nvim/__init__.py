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


path_ns_cache = {}

def get_customization_variable(nvim, var, default=None):
    return nvim.current.buffer.vars.get(var, nvim.vars.get(var, default))


def current_path(nvim):
    return nvim.funcs.getcwd()


def path_to_ns(nvim, fpath=None, force=False):
    log_debug("fpath is {}", fpath)
    if not fpath:
        fpath = nvim.funcs.expand("%:p:r")

    if fpath in path_ns_cache and not force:
        ns = path_ns_cache[fpath]
        log_debug("Hitting cache for ns '{}'", ns)
        return ns

    stop_paths = get_stop_paths(nvim)
    ns = pure.path_to_ns(fpath, stop_paths)
    path_ns_cache[fpath] = ns
    return ns


def get_port_no(nvim):
    pwd = current_path(nvim)

    with open(os.path.join(pwd, ".nrepl-port")) as port:
        return port.read().strip()


def repl_host_address(nvim):
    path = current_path(nvim)

    if path[-1] != "/":
        path = path + "/"

    ix = nvim.funcs.luaeval(
        "require('acid.connections').current[_A]",
        path)

    if ix != None:
        connection = nvim.funcs.luaeval(
        "require('acid.connections').store[_A]",
        ix)
        log_debug("Return from lua: {}", str(connection))

        return connection


    host = nvim.vars.get('acid_lein_host', '127.0.0.1')
    try:
        return [host, get_port_no(nvim)]
    except:
        return None


# Renamed the function, keeping this here to avoid breaking stuff..
localhost = repl_host_address


def format_addr(*addr):
    return "{}://{}:{}".format('nrepl', *addr)


def get_acid_ns(nvim, fpath=None):
    strategy = get_customization_variable(nvim, 'acid_ns_strategy', '')
    if 'ns:' in strategy:
        return strategy.split(':')[-1]
    return path_to_ns(nvim, fpath)


def test_paths(nvim):
    return {'test', *nvim.vars.get('acid_alt_test_paths', [])}


def src_paths(nvim):
    return {'src', *nvim.vars.get('acid_alt_paths', [])}


def get_stop_paths(nvim):
    return {'test', 'src', *test_paths(nvim), *src_paths(nvim)}


def find_file_in_path(nvim, fname, resource):
    log_debug("finding path")
    protocol, *_, fpath = fname.split(':')

    log_debug("Finding path to {}", fname )

    if protocol == 'file':
        if os.path.exists(fpath):
            return fpath
        elif resource != None:
            paths = get_stop_paths(nvim)

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
        if os.path.exists(full):
            return full

    return None

def alt_paths(path_arr, alt_paths, root, rename_fn):
    # clone array so we don't overwrite last element
    path = list(path_arr)[1:]
    path[-1] = pure.rename_file(path[-1], rename_fn)

    def existing(ap):
        alt_root = os.path.join(root, ap)
        if os.path.exists(alt_root):
            log_debug("Path {} exists", alt_root)
            return os.path.join(alt_root, *path)
        log_debug("Path {} doesn't exist", alt_root)
        return

    return filter(lambda i: i is not None, map(existing, alt_paths))
