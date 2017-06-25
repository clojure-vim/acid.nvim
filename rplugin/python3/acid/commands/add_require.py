from acid.commands import BaseCommand
from acid.nvim import get_acid_ns, find_clojure_fn
import os


class Command(BaseCommand):

    name = 'AddRequire'
    priority = 0
    enabled = 0
    handlers = ['MetaRepl']
    mapping = 'cdr'
    prompt = 1
    nargs = "*"
    op = "eval"

    def prepare_payload(self, *args):
        require = " ".join(args)
        self.nvim.command('exec "normal! mxgg/require\<CR>\\"sya)`x" | nohl')
        data = "(add-req '{} '[{}])".format(
            self.nvim.funcs.getreg("s"), require
        )

        return {'code': data}
