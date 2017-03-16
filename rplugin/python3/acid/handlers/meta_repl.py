from acid.handlers import SingletonHandler
from acid.zen.ui import build_window


def format_payload(payload):
    if type(payload) == str:
        return [payload]

    ls = []
    try:
        msg_id = payload.get('id', '****')
        for k, v in payload.items():
            key = k.lower()
            if key not in {'ns', 'session', 'id', 'op'}:
                if '\n' in v:
                    header, *trailer = v.split('\n')
                else:
                    header,  trailer = v, []

                if header.isspace() or header is "":
                    header, trailer = trailer[0], trailer[1:]

                ls.append("[{}][{: <9}] => {}".format(
                    str(msg_id)[-4:], key.upper(), str(header)
                ).strip())

                for i in trailer:
                    ls.append("{: <14} {}".format("", str(i)))
    finally:
        return ls

class Handler(SingletonHandler):

    name = "MetaRepl"

    def on_init(self):
        self.buf_nr = None
        self.cmd_buf_nr = None

    def insert_text(self, text):
        self.nvim.buffers[self.buf_nr].append(text)
        pos = len(self.nvim.buffers[self.buf_nr])
        self.nvim.funcs.setpos('.', [self.buf_nr, pos , 1, 0])

    def on_pre_handle(self, *_):

        no_shared_buffer = self.buf_nr is None
        has_no_window = self.nvim.funcs.bufwinnr(self.buf_nr) == -1

        if (no_shared_buffer or has_no_window):
            cmds = [
                'setlocal nolist nobuflisted buftype=nofile bufhidden=wipe',
                'file meta-repl',
            ]
            if self.nvim.funcs.exists(':AnsiEsc'):
                cmds.append('AnsiEsc')

            self.buf_nr = build_window(self.nvim, close=1, commands=cmds)

        no_cmd = self.cmd_buf_nr is None

        if no_cmd:
            send = """:exec 'normal! mx$?^("sy%`x' | nohl |
                call AcidSendNrepl({
                    'op': 'eval', 'code': getreg("s")
                }, 'MetaRepl')<CR>""".splitlines()

            send = "map <buffer> <silent> <localleader><CR> {}".format(
                "".join(map(str.strip, send))
            )
            self.cmd_buf_nr = build_window(
                self.nvim,
                close=1,
                orientation="rightbelow 20 split",
                commands=["set ft=clojure", send]
            )

    def on_pre_send(self, msg, *_):
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]

    def on_handle(self, msg, *_):
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]
