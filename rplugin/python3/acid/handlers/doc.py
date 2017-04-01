from acid.handlers import SingletonHandler
from acid.nvim.log import info, log_debug, warning
from acid.zen.ui import build_window


class Handler(SingletonHandler):

    name = "Doc"
    priority = 0

    def on_init(self, *_):
        self.doc_buf_nr = None

    def on_handle(self, msg, *_):
        if not 'no-info' in msg.get('status', []):
            name = msg['name']
            ns = msg.get('ns', '')

            arglist = msg.get('arglists-str', [])
            doc = msg.get('doc', '')
            javadoc = msg.get('javadoc', '')
            added = msg.get('added', '')
            super_ = msg.get('super', '')
            modifiers = msg.get('modifiers', [])
            see_also = msg.get('see-also', [])
            interfaces = msg.get('interfaces', [])

            if arglist:
                fn_calls = ["({}{})".format(name, " {}".format(i) if i else "")
                           for i in arglist[2:-2].split('] [')]
            else:
                fn_calls = [name]

            if see_also:
                see_also = ["https://clojuredocs.org/{}".format(i)
                            for i in see_also]

            docl = [i for i in [
                " ".join(fn_calls),
                ns,
                modifiers,
                " ",
                javadoc,
                *doc.split('\n'),
                " ",
                added and "Since version {}".format(added),
                interfaces and "Implements: {}".format(
                    ",".join(interfaces)
                ) or "",
                super_ and "Extends: {}".format(super_) or "",
                see_also and "See also:" or "",
                *see_also,
            ] if i ]

            no_doc_buffer = self.doc_buf_nr is None
            buf_win_nr = self.nvim.funcs.bufwinnr(self.doc_buf_nr)
            doc_len = len(docl)

            if no_doc_buffer or buf_win_nr == -1:
                cmds = ['file acid://doc',
                        'wincmd p',
                        ]

                self.doc_buf_nr = build_window(
                    self.nvim, close=1, commands=cmds, throwaway=1,
                    orientation="leftabove {} split".format(doc_len)
                )
            else:
                self.nvim.command('{} wincmd w | resize {} | wincmd p'.format(
                        buf_win_nr, doc_len
                ))

            info(self.nvim, "Documentation  for {}/{}".format(ns, name))
            log_debug(docl)
            exec_cmd = "bd {} | au! AcidDoc".format(self.doc_buf_nr)

            self.nvim.buffers[self.doc_buf_nr][:] = docl
            self.nvim.command('augroup AcidDoc')
            self.nvim.command('au!')
            self.nvim.command(
                'au CursorMoved * exec "{}"'.format(exec_cmd))
            self.nvim.command('augroup END')

        else:
            warning(self.nvim, "No information for symbol")
