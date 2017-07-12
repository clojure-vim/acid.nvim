from acid.commands import BaseCommand
from acid.nvim import get_acid_ns, find_clojure_fn
import os


class Command(BaseCommand):

    name = 'InjectFn'
    priority = 0
    enabled = 0
    handlers = ['Ignore']
    nargs=1
    op = "eval"

    def prepare_payload(self, fname):
        fpath = find_clojure_fn(self.nvim, fname)
        if fpath is None:
            self.nvim.command(
                "Acid: Couldn't find {} clojure file.".format(fname)
            )
            return None

        with open(fpath) as clj:
            content = "\n".join(clj.readlines())

        return {'code': content}
