from acid.handlers import BaseHandler
from acid.nvim.log import echo_warning


# Not exactly correct. Must update all open buffers related to change,
# Including the one which was moved.

class Handler(BaseHandler):

    name = "MvSingle"
    priority = 0

    def on_handle(self, msg, *_):
        if 'error' in msg:
            echo_warning(self.nvim, msg['error'])
        else:
            path = msg['touched'][0]
            self.nvim.command('edit {}'.format(path))

