from acid.commands import BaseCommand
from acid.nvim import get_acid_ns


class Command(BaseCommand):

    name = 'Eval'
    priority = 0
    cmd_name = 'AcidEval'
    handlers = ['MetaRepl']
    mapping = 'cp'
    opfunc = True
    nargs='*'
    op = "eval"
    shorthand = '''normal! mx$?^(\<lt>CR>\\"sy%`x'''

    def prepare_payload(self, *args):

        return {"code": " ".join(args), "ns": get_acid_ns(self.nvim)}
