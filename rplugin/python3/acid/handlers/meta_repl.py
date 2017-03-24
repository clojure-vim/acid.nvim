# -*- coding: utf-8 -*-
from acid.handlers import SingletonHandler
from acid.zen.ui import build_window
import logging

logger = logging.getLogger(__name__)
fh = logging.FileHandler('/tmp/acid-log-handler.log', encoding='utf-8')
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)
logger.setLevel(logging.DEBUG)

def format_dict(d):
    lines = []
    for k, v in d.items():
        if type(v) == dict:
            data = format_dict(v)
        elif type(v) == list:
            data = v
        else:
            data = [v]

        logger.debug("Pre-parsed data: {}".format(str(data)))

        if not data:
            lines.append("{: <10} → []".format(k))
        else:
            i, *j = data
            lines.append("{: <10} → {}".format(k, str(i).replace('\n','')))
            [lines.append("{: <12} {}".format("", str(l).replace('\n','')))
             for l in j]
            logger.debug("Produced {} lines".format(len(lines)))

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
                    logger.debug('v is a list')
                    header, trailer = v[0], v[1:]
                elif type(v) == dict:
                    logger.debug('v is a dict')
                    formatted = format_dict(v)
                    logger.debug('Got {}'.format(str(formatted)))
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
        logger.error("Couldn't finish producing output: {}".format(str(e)))
    finally:
        if len(ls) == 0:
            logger.warn("Empty output for ls: {}".format(str(payload)))
        return ls

class Handler(SingletonHandler):

    name = "MetaRepl"
    priority = 0

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

        if no_shared_buffer:
            cmds = ['file acid://meta-repl',
                    'nnoremap <buffer> <localleader><CR> :e<CR>',
                    'nnoremap <buffer> <localleader><localleader> kdggjdG',
                    'nnoremap <buffer> <localleader>D kdgg',
                    'nnoremap <buffer> <localleader>d jdG',]
            if self.nvim.funcs.exists(':AnsiEsc'):
                cmds.append('AnsiEsc')

            self.buf_nr = build_window(
                self.nvim, close=1, commands=cmds, throwaway=1
            )

        use_cmd_win = bool(self.nvim.vars.get(
            'acid_meta_repl_use_cmd_window', False
        ))

        if use_cmd_win:
            no_cmd = self.cmd_buf_nr is None
            has_no_cmd_window = self.nvim.funcs.bufwinnr(self.cmd_buf_nr) == -1

            if no_cmd:
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
                    commands=['file acid://scratchpad',
                              'set ft=clojure',
                              send,
                              "let b:acid_ns_strategy='ns:user'"]
                )

    def on_pre_send(self, msg, *_):
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]

    def on_handle(self, msg, *_):
        [self.insert_text(i) for i in format_payload(msg) if not i.isspace()]
