# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    localhost, path_to_ns,
    find_file_in_path, find_extensions, import_extensions
)
from acid.session import send, SessionHandler


@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim
        self.sessions = SessionHandler()
        self.handlers = {}
        self.init_handlers()

    def init_handlers(self):
        for path in find_extensions(self.nvim, 'handlers'):
            handler = import_extensions(path, 'handlers', 'Handler')
            if handler:
                name = handler.name

                if name not in self.handlers:
                    self.handlers[name] = handler
                    handler.init_handler(self.nvim)

    @neovim.function("AcidEval")
    def acid_eval(self, data):
        handler = self.handlers.get('Proto')
        address = localhost(self.nvim)
        send(self.nvim, self.sessions, address, handler, **data[0])
