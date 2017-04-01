from acid.handlers import BaseHandler
from acid.nvim.log import war

class Handler(BaseHandler):

    name = "Ignore"
    priority = 0

    def on_handle(self, msg, *_):
        if 'err' in msg:
            warning(msg['err'])

