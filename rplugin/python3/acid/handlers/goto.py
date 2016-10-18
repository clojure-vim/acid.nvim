from acid.handlers import BaseHandler
from acid.nvim import find_file_in_path


class Handler(BaseHandler):

    name = "Goto"

    def __init__(self, nvim):
        self.nvim = nvim

    def on_handle(self, msg, *_):
        if 'file' in msg:
            f = find_file_in_path(self.nvim, msg)
            if f is None:
                self.nvim.command("echo 'File not found'")
                return
            self.nvim.command("edit {}".format(f))

        c = msg.get('column', 1)
        l = msg.get('line', 1)

        self.nvim.funcs.cursor(l, c)

