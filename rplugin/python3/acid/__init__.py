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
        self.repls = {}
        self.extensions = {'handlers': {},
                           'commands': {}}
        self._init = False

    @neovim.command("AcidInit")
    def init(self):
        self.init_extensions('handlers', 'Handler')
        self.init_extensions('commands', 'Command')
        self.init_vars()
        self._init = True

    def init_vars(self):
        def init_var(var, default=0):
            self.nvim.vars[var] = self.nvim.vars.get(var, default)

        [init_var(i, j)
         for i, j
         in [('acid_loaded', 1),
             ('acid_log_messages', 0),
             ('acid_auto_require', 1),
             ('acid_auto_start_repl', 0),
             ('acid_namespace', 'user'),
             ('acid_start_repl_fn', 'jobstart'),
             ('acid_start_repl_args', ['lein repl'])]]

    def init_extensions(self, ext_type, klass):
        for path in find_extensions(self.nvim, ext_type):
            extension = import_extensions(path, ext_type, klass)

            if extension:
                name = extension.name

                if name not in self.extensions[ext_type]:
                    self.extensions[ext_type][name] = extension
                    if ext_type == 'commands':
                        extension.do_init(self.nvim)

    def add_log_to(self, url):
        log = self.extensions['handlers'].get('Log').do_init(self.nvim)
        self.sessions.add_persistent_watch(url, log)

    def command(self, data, handlers):
        address = localhost(self.nvim)

        if address is None:
            self.nvim.command('echom "No repl open"')
            return

        url = "nrepl://{}:{}".format(*address)

        if self.nvim.vars['acid_log_messages']:
            self.add_log_to(url)

        if not 'op' in data:
            data.update({'op': 'eval'})

        send(self.sessions, url, handlers, data)

    @neovim.command("AcidCommand", nargs=1)
    def acid_command(self, args):
        command = self.extensions['commands'].get(args[0].strip())
        command.call(self)

    @neovim.function("AcidSendNrepl")
    def acid_eval(self, data):
        payload = data[0]
        handler = len(data) > 1 and data[1] or 'Proto'
        config = len(data) > 2 and data[2] or None
        handler_cls = self.extensions['handlers'].get(handler, None)

        if handler is not None:
            handler = handler_cls.do_init(self.nvim)

            if config is not None:
                handler = handler.configure(config)

            self.command(payload, [handler])
        else:
            self.nvim.command('echom "Handler not found"')

    @neovim.command("AcidRequire")
    def acid_require(self):
        data = "(require '[{} :refer :all])".format(path_to_ns(self.nvim))
        self.eval({"code": data}, [[self.extensions['handlers']['Ignore'], {}]])

