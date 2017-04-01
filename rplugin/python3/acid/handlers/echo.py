from acid.handlers import BaseHandler

class Handler(BaseHandler):

    name = "Echo"
    priority = 0

    def on_init(self):
        self.value = []

    def on_handle(self, msg, *_):
        if 'out' in msg:
            self.value.append(msg['out'])
        elif 'err' in msg:
            self.value.append(msg['err'])
        elif 'value' in msg:
            self.value.append("\n" + msg['value'])

    def on_after_finish(self, *_):
        escaped_str = self.nvim.call("string", "".join(self.value))
        self.nvim.command('echo {}'.format(escaped))
