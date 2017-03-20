from acid.handlers import BaseHandler

class Handler(BaseHandler):

    name = "Echo"
    priority = 0

    def on_handle(self, msg, *_):
        value = None
        if 'out' in msg:
            value = msg['out']
        elif 'err' in msg:
            value = msg['err']
        elif 'value' in msg:
            value = msg['value']

        if value is not None:
            self.nvim.command('echo "{}"'.format(value))

