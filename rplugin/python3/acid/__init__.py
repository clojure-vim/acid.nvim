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
from acid.session import ThinSession
import os

def get(ls, ix, default=None):
    return len(ls) > ix and ls[ix] or default

def should_finalize(msg):
    return 'status' in msg

def partial_handler(nvim):
    def fn(finalizer):
        def handler(msg, wc, key):
            try:
                nvim.async_call(
                    lambda: nvim.exec_lua(
                        "require('acid').callback(...)", msg, async_ = True)
                )
                log_info(msg)
            finally:
                if should_finalize(msg):
                    finalizer(msg, wc, key)

        return handler
    return fn

@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim
        self.session_handler = ThinSession()

    @neovim.function("AcidSendNrepl")
    def acid_eval(self, data):
        payload, addr = data
        url = format_addr(*addr)
        success, msg = self.session_handler.send(url, payload,
                                                 partial_handler(self.nvim))

        if not success:
            self.nvim.api.err_writeln(
                "Error on nrepl connection: {}".format(msg))

        return success

    @neovim.function("AcidGetNs", sync=True)
    def acid_get_ns(self, args):
        return get_acid_ns(self.nvim, *args)

    @neovim.function("AcidFindFileInPath", sync=True)
    def find_fpath(self, args):
        log_info("Finding path")
        return find_file_in_path(nvim, *args)

    @neovim.function("AcidNewUUID", sync=True)
    def acid_get_uuid(self, args):
        return uuid.uuid4().hex

    @neovim.function("AcidLog", sync=False)
    def acid_log(self, args):
        ns, message, *_ = args
        logger = logging.getLogger(ns)
        logger.debug(message)

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
                    lambda f: "_".join(f.split('_')[:-1])
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
        log_debug("Args: {}", args)
        if not has_path:
            fname = "{}.clj".format(ns_to_path(ns))
            base = 'test' if ns.endswith('-test') else 'src'
            current_path = self.nvim.funcs.getcwd()
            path = os.path.join(current_path, base, fname)
        else:
            path = args[1]

        log_debug("path: {}", path)

        if os.path.exists(path):
            log_debug("File already exists. Aborting.")
            return path

        directory = os.path.dirname(path)

        if not os.path.exists(directory):
            os.makedirs(directory)

        with open(path, 'w') as fpath:
            fpath.write('(ns {})'.format(ns))

        return path
