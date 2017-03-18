from acid.handlers import BaseHandler
from acid.nvim import find_file_in_path
from zen.string import produce_select_options
from zen.ui import selection_window


class Handler(BaseHandler):

    name = "FileList"
    priority = 0

    def on_init(self):
        self.acc = {}

    def on_handle(self, msg, *_):
        if 'occurrence' in msg:
            path = msg['occurrence']['file'].split('/')

            key = "{} {} @ {}:{}".format(
                path[-1],
                "/".join(path[:-1]),
                msg['occurrence']['line-beg'],
                msg['occurrence']['col-beg'],
            )

            self.acc[key] = ':exec "bd! % \| edit +{} {}"<CR>'.format(
                msg['occurrence']['line-beg'],
                msg['occurrence']['file']
            )

    def after_finish(self):
        selection_window(
            self.nvim,
            select_options=self.acc
        )
