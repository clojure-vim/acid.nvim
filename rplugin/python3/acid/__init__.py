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


@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim
        self.commands = []
        self.sessions = SessionHandler()
        self.fired_urls = set()
        self.repls = {}
        self.extensions = {'handlers': {},
                           'commands': {}}
        self._init = False

    def context(self):
        return {
            'handlers': self.extensions['handlers'],
            'commands': self.extensions['commands'],
            'session_handler': self.sessions,
            'url': formatted_localhost_address(self.nvim),
            'nvim': self.nvim
        }

    @neovim.command("AcidInit")
    def init(self):
        self.init_vars()
        self.init_extensions({
            'handlers': 'Handler',
            'commands': 'Command',
        })
        self._init = True

    def init_commands(self):
        cmds = deque()
        for command in self.extensions['commands'].values():
            cmds.extend(command.do_init(self.nvim))

        return list(cmds)

    def init_vars(self):
        def init_var(var, default=0):
            self.nvim.vars[var] = self.nvim.vars.get(var, default)

        [init_var(i, j)
         for i, j
         in [('acid_loaded', 1),
             ('acid_log_messages', 0),
             ('acid_auto_require', 1),
             ('acid_auto_start_repl', 0),
             ('acid_sessions', []),
             ('acid_namespace', 'user'),
             ('acid_start_repl_fn', 'jobstart'),
             ('acid_start_repl_args', ['lein repl'])]]


    def init_extensions(self, ext_mapping):
        for path in find_extensions(self.nvim, ext_mapping.keys()):
            ext_type, extension = import_extensions(path, ext_mapping)

            if extension:
                name = extension.name
                priority = extension.priority
                enabled = bool(self.nvim.vars.get(
                    "{}_{}_enabled".format(
                        convert_case(name), ext_type.lower()
                    ), getattr(extension, 'enabled', 1)
                ))

                if enabled and (name not in self.extensions[ext_type] or
                        self.extensions[ext_type][name].priority < priority):
                    self.extensions[ext_type][name] = extension

    def get_handler(self, name):
        return self.extensions['handlers'].get(name).do_init()

    def add_log_to(self, url):
        log = self.get_handler('Log').configure(**self.context())
        self.sessions.add_persistent_watch(url, log)

    def command(self, data, handlers, url):
        acid_session = self.nvim.vars.get('acid_current_session')

        if get_customization_variable(self.nvim, 'acid_log_messages', 0):
            handlers = (i for i in (
                *handlers, self.get_handler('Log').configure(**self.context())
            ))

        if not 'op' in data:
            data.update({'op': 'eval'})

        if acid_session:
            data.update({'session': acid_session})

        if url not in self.sessions.sessions and url not in self.fired_urls:
            self.nvim.command("doautocmd User AcidPreConnectNrepl")
            self.fired_urls.add(url)

        send(self.sessions, url, handlers, data)


    @neovim.command("AcidUnsetSession")
    def acid_unset_session(self):
        del self.nvim.vars['acid_current_session']

    @neovim.command("AcidUseLastSession")
    def acid_unset_session(self):
        self.nvim.vars[
            'acid_current_session'] = self.nvim.vars['acid_sessions'][-1]

    @neovim.command("AcidCommand", nargs='*')
    def acid_command(self, args):
        cmd, *args = args
        log_info(r"Received args for command {}: {}", cmd, args)
        command = self.extensions['commands'].get(cmd.strip())

        url = formatted_localhost_address(self.nvim)

        if url is None and command.handlers:
            path = current_path(self.nvim)
            echo(self.nvim, "No REPL open")
            log_info("No repl open on path {}".format(path))
            return

        command.call(self, self.context(), *args)

    @neovim.function("AcidCommandMeta", sync=True)
    def acid_command_meta(self, args):
        cmd, meta_key, *args = args
        log_info(r"Prompting metadata {} for command {} with args {}",
                 meta_key, cmd, args)

        command = self.extensions['commands'].get(cmd.strip())
        if command is None:
            log_warning('Command not found. Aborting!')
            return None

        ret = getattr(command, meta_key)(self.nvim, *args)
        log_info(r"Got {} as a return for {}[{}]".format(ret, cmd, meta_key))
        return ret

    @neovim.command("AcidBootstrap", nargs=0, bang=True)
    def acid_bootstrap(self, bang=False):
        if bang or not self.commands:
            self.commands = self.init_commands()

        [self.nvim.command(cmd) for cmd in self.commands]
        self.nvim.command("doautocmd User AcidBootstrapComplete")

    @neovim.function("AcidSendNrepl")
    def acid_eval(self, data):
        payload = data[0]
        handler = len(data) > 1 and data[1] or 'MetaRepl'
        config = len(data) > 2 and data[2] or None
        url = (format_addr(*data[3]) if len(data) > 3
               else formatted_localhost_address(self.nvim))


        handler = self.get_handler(handler)

        if handler is None:
            warning(self.nvim, "Handler not found")
            return

        context = self.context()

        if config is not None:
            handler = handler.configure(config, **context)
        else:
            handler = handler.configure(**context)

        self.command(payload, [handler], url)

    @neovim.function("AcidGetNs", sync=True)
    def acid_get_ns(self, args):
        return get_acid_ns(self.nvim)

    @neovim.function("AcidGetUrl", sync=True)
    def acid_get_url(self, args):
        return repl_host_address(self.nvim)

    @neovim.function("Acid_FindFileInPath", sync=True)
    def acid_get_url(self, args):
        return find_file_in_path(nvim, args[0])
