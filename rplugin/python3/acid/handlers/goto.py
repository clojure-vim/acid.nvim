from acid.handlers import BaseHandler
from acid.nvim import find_file_in_path
from acid.nvim.log import log_info, error, warning


class Handler(BaseHandler):

    name = "Goto"
    priority = 0

    def on_handle(self, msg, *_):
        if 'file' in msg:
            f = find_file_in_path(self.nvim, msg)

            if f is None:
                warning(self.nvim, "File not found")
                return

            c = msg.get('column', 1)
            l = msg.get('line', 1)

            current_scrolloff = self.nvim.options['scrolloff']
            self.nvim.options['scrolloff'] = 999

            try:
                if self.nvim.funcs.expand('%').endswith(f):
                    self.nvim.funcs.cursor(l, c)
                else:
                    self.nvim.command("edit +{} {}".format(l, f))
            except Exception as e:
                error(self.nvim, "Error while navigating: {}".format(str(e)))
            finally:
                self.nvim.options['scrolloff'] = current_scrolloff

        elif 'no-info' in msg['status']:
            warning(self.nvim, 'No information found for symbol')
