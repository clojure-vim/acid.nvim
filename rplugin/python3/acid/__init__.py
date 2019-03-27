# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
import logging
import uuid
from acid.nvim import (
    format_addr, get_acid_ns, find_file_in_path, repl_host_address,
    alt_paths, src_paths, test_paths
)

from acid.pure import ns_to_path
from acid.nvim.log import log_info, log_debug, fh
from acid.session import send, SessionHandler
import os

def get(ls, ix, default=None):
    return len(ls) > ix and ls[ix] or default

def lua(nvim, lua_cmd):
    def impl(msg, *_):
        nvim.exec_lua(lua_cmd, msg)

    return impl

def vim(nvim, vim_fn):
    def impl(msg, *_):
        nvim.call(vim_fn, msg)

    return impl

def should_finalize(msg):
    return ('status' in msg and
             not set(msg['status']).intersection({'eval-error', }))

def new_handler(nvim, handler_impl, finalizer):
    def handler(msg, wc, key):
        try:
            nvim.async_call(lambda: handler_impl(msg, wc, key))
        finally:
            if should_finalize(msg):
                finalizer(msg, wc, key)

    return handler

handlers = {
    "lua": lua,
    "vim": vim
}

def partial_handler(nvim, handler):
    def impl(finalizer):
        return new_handler(nvim, handler, finalizer)
    return impl

@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        log_handler = new_handler(
            nvim,
            lambda msg, *_: not "changed-namespaces" in msg and log_info(msg),
            lambda *_: False
        )

        self.nvim = nvim
        self.session_handler = SessionHandler(log_handler)

    @neovim.function("AcidSendNrepl")
    def acid_eval(self, data):
        nvim = self.nvim
        payload = data[0]
        fn = data[1] # fn name
        addr = get(data, 2)
        addr_managed_by_acid = addr != None
        addr = addr or repl_host_address(nvim)
        url = format_addr(*addr)
        backend = get(data, 3) or "lua"

        handler_impl = handlers[backend](nvim, fn)
        handler = partial_handler(nvim, handler_impl)

        success, msg = send(self.session_handler, url, [handler], payload)

        if not success and addr_managed_by_acid:
            nvim.api.err_writeln(
            "Dropping connection on {} due to error when sending: {}".format(
                addr[1], msg))
            nvim.funcs.luaeval("require('acid.connections'):remove(_A)", addr)

    @neovim.function("AcidGetNs", sync=True)
    def acid_get_ns(self, args):
        return get_acid_ns(self.nvim, get(args, 0))

    @neovim.function("AcidFindFileInPath", sync=True)
    def find_fpath(self, args):
        log_info("Finding path")
        return find_file_in_path(nvim, *args)

    @neovim.function("AcidNewUUID", sync=True)
    def acid_get_uuid(self, args):
        return uuid.uuid4().hex

    @neovim.function("AcidLog", sync=False)
    def acid_log(self, args):
        ns, level, message, *_ = args
        logger = logging.getLogger(ns)
        logger.addHandler(fh)
        logger.setLevel(logging.DEBUG)
        getattr(logger , level.upper())(message)

    @neovim.function("AcidAlternateFiles", sync=True)
    def acid_alternate_file(self, args):
        try:
            src = src_paths(self.nvim)
            path = get(args, 0, self.nvim.funcs.expand("%:p"))
            log_info("Finding alternate file for {}", path)
            root_path = self.nvim.funcs.getcwd()
            rel_path = os.path.relpath(path, start=root_path).split('/')

            if rel_path[0] in src:
                paths = alt_paths(
                    rel_path, test_paths(self.nvim), root_path,
                    lambda f: '{}_test'.format(f),
                )
            else:
                paths = alt_paths(
                    rel_path, src, root_path,
                    lambda f: "_".join(f.split('_')[:-1]),
                    'src'
                )
        except Exception as e:
            log_debug("error: {}", e)
            paths = []

        log_debug("paths: {}", paths)

        return list(paths)

    @neovim.function("AcidNewFile", sync=True)
    def acid_new_file(self, args):
        ns = args[0]
        has_path = len(args) > 1
        if not has_path:
            fname = "{}.clj".format(ns_to_path(ns))
            base = 'test' if ns.endswith('-test') else 'src'
            current_path = self.nvim.funcs.getcwd()
            path = os.path.join(current_path, base, fname)
        else:
            path = args[1]

        if os.path.exists(path):
            log_debug("File already exists. Aborting.")
            return path

        directory = os.path.dirname(path)

        if not os.path.exists(directory):
            os.makedirs(directory)

        with open(path, 'w') as fpath:
            fpath.write('(ns {})'.format(ns))

        return path
