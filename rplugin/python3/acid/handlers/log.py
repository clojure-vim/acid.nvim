from acid.handlers import SingletonHandler
from acid.nvim.log import log_info


class Handler(SingletonHandler):

    name = "Log"
    priority = 0
    finalizer = lambda *_: False

    def on_handle(self, msg, *_):
        if not 'state' in msg.get('status', []):
            log_info(msg)
