from acid.handlers import SingletonHandler
from acid.nvim.extras import build_window


def format_payload(payload):
    if type(payload) == str:
        return [payload]

    ls = []
    try:
        session = payload.get('session', '****')
        for k, v in payload.items():
            key = k.lower()
            if key not in {'ns', 'session', 'id'}:
                if '\n' in v:
                    header, *trailer = v.split('\n')
                else:
                    header,  trailer = v, []

                if header.isspace() or header is "":
                    header, trailer = trailer[0], trailer[1:]

                ls.append("[{}][{: <9}] => {}".format(
                    str(session)[-4:], key.upper(), str(header)
                ).strip())

                for i in trailer:
                    ls.append("{: <14} {}".format("", str(i)))
    finally:
        return ls

class Handler(SingletonHandler):

    name = "SharedProto"

    def on_init(self):
        self.buf_nr = None

    def on_pre_handle(self, *_):

        no_shared_buffer = self.buf_nr is None
        has_no_window = self.nvim.funcs.bufwinnr(self.buf_nr) == -1

        if (no_shared_buffer or has_no_window):
            self.buf_nr = build_window(self.nvim, nolist=1, ansiesc=1)

    def on_handle(self, msg, *_):
        [self.nvim.buffers[self.buf_nr].append(i)
         for i
         in format_payload(msg)
         if not i.isspace()]
