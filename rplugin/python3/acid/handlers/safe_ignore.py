from acid.handlers import BaseHandler

class Handler(BaseHandler):

    name = "Ignore"

    def on_handle(self, msg, *_):
        if 'ex' in msg:
            self.nvim.command('echom "Acid: Exception {}"'.format(msg['ex']))

