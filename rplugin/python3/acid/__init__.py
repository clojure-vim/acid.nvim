# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    path_to_ns, format_addr, formatted_localhost_address, get_acid_ns,
    find_file_in_path, find_extensions, import_extensions,
    convert_case, get_customization_variable, current_path,
    repl_host_address
)
from collections import deque
from acid.nvim import find_file_in_path
from acid.nvim.log import log_info, echo, warning, info
from acid.session import send, SessionHandler

def get(ls, ix):
    return len(ls) > ix and ls[ix]

def lua(nvim, lua_cmd):
    def impl(msg, *_):
        nvim.funcs.luaeval(lua_cmd, msg)

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
        log_info(msg)
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
            lambda msg, *_: log_info(msg),
            lambda *_: False
        )

        self.nvim = nvim
        self.session_handler = SessionHandler(log_handler)

    @neovim.function("AcidSendNrepl")
    def acid_eval(self, data):
        nvim = self.nvim
        payload = data[0]
        fn = data[1] # fn name
        addr = get(data, 2) or repl_host_address(nvim)
        url = format_addr(*addr)
        backend = get(data, 3) or "lua"

        handler_impl = handlers[backend](nvim, fn)
        handler = partial_handler(nvim, handler_impl)

        send(self.session_handler, url, [handler], payload)

    @neovim.function("AcidGetNs", sync=True)
    def acid_get_ns(self, args):
        return get_acid_ns(self.nvim)

    @neovim.function("AcidGetUrl", sync=True)
    def acid_get_url(self, args):
        return repl_host_address(self.nvim)

    @neovim.function("Acid_FindFileInPath", sync=True)
    def acid_get_url(self, args):
        return find_file_in_path(nvim, args[0])
