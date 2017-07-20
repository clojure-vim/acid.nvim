from acid.commands import BaseCommand
from acid.zen.ui import build_window
from acid.nvim.log import warning
import random
import os


class Command(BaseCommand):

    name = 'Scratchpad'
    priority = 0
    nargs=0
    handlers = []
    mapping = 'csp'

    @staticmethod
    def prompt_default(nvim):
        path = nvim.funcs.expand('%:p:h')
        return "{}.".format(path_to_ns(path))


    def prepare_payload(self):
        send = "map <buffer> <silent> <localleader><CR> {}".format(
            "".join(map(
                str.strip,
                """:call AcidSendNrepl({'op': 'eval',
                'code': join(getline(1, '$'), '\\n')}, 'MetaRepl')
                <CR>""".splitlines()
            ))
        )

        cmds = ['file acid://scratch-buffer-()'.format(random.randint(0, 100)),
                'set ft=clojure',
                'let b:acid_ns_strategy="ns:user"',
                send,
                ]


        build_window(
            self.nvim,
            close=1,
            throwaway=1,
            orientation="rightbelow 50 split",
            commands=cmds,
        )

        return None
