from acid.handlers import BaseHandler
from acid.nvim.log import error


class Handler(BaseHandler):

    name = "VimFn"
    priority = 0

    def on_init(self):
        self.vim_fn = ""
        self.value = []

    def on_configure(self, vim_fn, *args, **kwargs):
        self.vim_fn = vim_fn

    def on_handle(self, msg, *_):
        self.value.append(msg)

    def on_after_finish(self, *_):
        try:
            if self.vim_fn:
                self.nvim.call(self.vim_fn, self.value)
        except Exception as e:
             error(self.nvim, str(e))
