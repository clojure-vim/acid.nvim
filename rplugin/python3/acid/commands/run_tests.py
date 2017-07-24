from acid.commands import BaseCommand
from acid.nvim import get_acid_ns, find_clojure_fn
import os


class Command(BaseCommand):

    name = 'RunTests'
    priority = 0
    enabled = 0
    handlers = ['Ignore']
    nargs='*'
    op = "eval"
    requires = ['acid.test.report']

    def prepare_payload(self, *args):
        pass
