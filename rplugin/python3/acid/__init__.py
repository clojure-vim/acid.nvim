# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    localhost, path_to_ns, get_acid_ns,
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

    def get_handler(self, handler):
        if isinstance(handler, (tuple, list)):
            handler, match = handler
        else:
            handler, match = handler, {}

        return (self.handlers.get(handler), match)

    def eval(self, data, *handlers):
        address = localhost(self.nvim)
        handlers = [self.get_handler(i) for i in handlers]

        if not 'op' in data:
            data.update({'op': 'eval'})

        if not 'ns' in data:
            data.update({'ns': get_acid_ns(self.nvim)})

        send(self.sessions, address, handlers, data)

    @neovim.function("AcidEval")
    def acid_eval(self, data):
        payload = data[0]
        self.eval(payload, "Proto")

    @neovim.function("AcidGoTo")
    def acid_goto(self, data):
        payload = {"op": "info", "symbol": data[0]}
        self.eval(payload, ("Goto", {"resource": None}))

    @neovim.command("AcidGoToDefinition")
    def acid_goto_def(self):
        self.nvim.command('normal! "syiw')
        data = self.nvim.funcs.getreg('s')
        self.acid_goto([data])

    @neovim.command("AcidRequire")
    def acid_require(self):
        data = "(require '[{} :refer :all])".format(path_to_ns(self.nvim))
        self.eval({"code": data}, "Ignore")
