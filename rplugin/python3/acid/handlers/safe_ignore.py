from acid.handlers import BaseHandler

class Handler(BaseHandler):

    name = "Ignore"
    priority = 0

    def on_handle(self, msg, *_):
        if 'err' in msg:
            self.nvim.command('echom "Acid: {}"'.format(msg['err']))

