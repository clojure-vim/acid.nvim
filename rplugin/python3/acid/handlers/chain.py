from acid.handlers import BaseHandler
from acid.nvim import find_file_in_path


class Handler(BaseHandler):

    name = "Chain"

    def add_acid(self, acid):
        self.acid = acid
        return self

    def set_transform(self, fn):
        self.transform = fn

    def set_handlers(self, *handler):
        self.handlers = handler

    def on_handle(self, msg, *_):
        handlers = map(self.acid.extensions['handlers'].get, self.handlers)
        handlers = map(lambda h: h.do_init(self.nvim), handlers)

        self.acid.command(self.transform(msg), handlers)
