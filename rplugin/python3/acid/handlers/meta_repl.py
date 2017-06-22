# -*- coding: utf-8 -*-
import random
from acid.handlers import SingletonHandler
from acid.zen.ui import build_window
from acid.nvim.log import log_debug, log_info, log_warning, log_error

def format_dict(d):
    lines = []
    for k, v in d.items():
        if type(v) == dict:
            data = format_dict(v)
        elif type(v) == list:
            data = v
        else:
            data = [v]

        log_debug("Pre-parsed data: {}", str(data))

        if not data:
            lines.append("{: <10} → []".format(k))
        else:
            i, *j = data
            lines.append("{: <10} → {}".format(k, str(i).replace('\n','')))
            [lines.append("{: <12} {}".format("", str(l).replace('\n','')))
             for l in j]
            log_debug("Produced {} lines", len(lines))

    return lines


def format_payload(payload):
    if type(payload) == str:
        return [payload]

    ls = []
    try:
        msg_id = payload.get('id', '****')
        for k, v in payload.items():
            key = k.lower()
            if key not in {'ns', 'session', 'id', 'op'}:
                if type(v) == list:
                    log_debug('v is a list')
                    header, trailer = v[0], v[1:]
                elif type(v) == dict:
                    log_debug('v is a dict')
                    formatted = format_dict(v)
                    log_debug('Got {}', str(formatted))
                    if len(formatted) > 0:
                        header, *trailer = formatted
                    else:
                        header = []
                elif '\n' in v:
                    header, *trailer = v.split('\n')
                else:
                    header, trailer = v, []

                if not header:
                    next

                if header.isspace() or header is "":
                    header, trailer = trailer[0], trailer[1:]

                ls.append("[{}][{: <9}] => {}".format(
                    str(msg_id)[-4:], key.upper(), str(header)
                ).strip())

                for i in trailer:
                    ls.append("{: <20} {}".format("", str(i)))
    except e:
        log_error("Couldn't finish producing output: {}", str(e))
    finally:
        if len(ls) == 0:
            log_warning("Empty output for ls: {}", str(payload))
        return ls

class Handler(SingletonHandler):

    name = "MetaRepl"
    priority = 0

    def ensure_win_exists(self):
        no_shared_buffer = self.buf_nr is None
        has_no_window = self.nvim.funcs.bufwinnr(self.buf_nr) == -1

        log_debug("buf_nr is {}", self.buf_nr)
        log_debug("has window? {}", has_no_window)

        if no_shared_buffer or has_no_window:
            self.random = random.randint(0, 100)
            cmds = ['file acid://meta-repl-{}'.format(self.random),
                    'nnoremap <buffer> <localleader><CR> :e<CR>',
                    'nnoremap <buffer> <localleader><localleader> kdggjdG',
                    'nnoremap <buffer> <localleader>D kdgg',
                    'nnoremap <buffer> <localleader>d jdG',
                    ]

            self.buf_nr = build_window(
                self.nvim, close=1, commands=cmds, throwaway=1,
            )
            log_debug("Set buf_nr to {}", self.buf_nr)

    def ensure_cmd_win_exists(self):
        use_cmd_win = bool(self.nvim.vars.get(
            'acid_meta_repl_use_cmd_window', False
        ))

        log_debug("use cmd win? is {}", self.use_cmd_win)

        if use_cmd_win:
            no_cmd = self.cmd_buf_nr is None
            has_no_cmd_window = self.nvim.funcs.bufwinnr(self.cmd_buf_nr) == -1

            if no_cmd or has_no_cmd_window:
                send = """:call AcidSendNrepl({
                    'op': 'eval', 'code': join(getline(1, '$'), '\\n')
                    }, 'MetaRepl')<CR>""".splitlines()

                send = "map <buffer> <silent> <localleader><CR> {}".format(
                    "".join(map(str.strip, send))
                )
                meta_repl_window = self.nvim.funcs.bufwinnr(self.buf_nr)
                nvim.command("{} wincmd w".format(meta_repl_window))

                self.cmd_buf_nr = build_window(
                    self.nvim,
                    close=1,
                    throwaway=1,
                    orientation="rightbelow 20 split",
                    commands=['file acid://meta-repl-{}/scratchpad'.format(
                                    self.random),
                              'set ft=clojure',
                              send,
                              "let b:acid_ns_strategy='ns:user'"]
                )


    def on_init(self):
        self.buf_nr = None
        self.cmd_buf_nr = None

    def insert_text(self, text):
        self.nvim.buffers[self.buf_nr].append(text)
        pos = len(self.nvim.buffers[self.buf_nr])
        self.nvim.funcs.setpos('.', [self.buf_nr, pos , 1, 0])

    def on_pre_handle(self, *_):
        self.ensure_win_exists()
        # self.ensure_cmd_win_exists()

    def on_pre_send(self, msg, *_):
        self.ensure_win_exists()
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]

    def on_handle(self, msg, *_):
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]
