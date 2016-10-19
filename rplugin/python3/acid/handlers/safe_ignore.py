from acid.handlers import BaseHandler

class Handler(BaseHandler):

    name = "Ignore"

    def __init__(self, nvim):
        self.nvim = nvim

    def on_handle(self, msg, *_):
        if 'ex' in msg:
            self.nvim.command('echoerr "Acid: Exception {}"'.format(msg['ex']))

