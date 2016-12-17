from acid.handlers import BaseHandler
from acid.nvim import find_file_in_path
from zen.string import produce_select_options
from zen.ui import selection_window


class Handler(BaseHandler):

    name = "FileList"

    def on_init(self):
        self.acc = {}

    def on_handle(self, msg, *_):
        key = msg['occurrence']['name']
        self.acc[key] = ':edit +{} {}'.format(msg['line-beg'], msg['file'])

    def after_finish(self):
        selection_window(
            self.nvim,
            header="Select file",
            select_options=produce_select_options(self.acc)
        )
