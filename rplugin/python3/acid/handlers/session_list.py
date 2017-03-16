from acid.handlers import SingletonHandler


class Handler(SingletonHandler):

    name = "SessionAdd"

    def on_handle(self, msg, *_):
        sessions = self.nvim.vars.get('acid_sessions', [])
        self.nvim.vars['acid_sessions'] = [msg['new-session'], *sessions]
