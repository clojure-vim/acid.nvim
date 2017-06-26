from acid.commands import BaseCommand
from acid.pure import parser
from acid.nvim import get_acid_ns, log


class Command(BaseCommand):

    name = 'Eval'
    priority = 0
    handlers = ['MetaRepl']
    mapping = 'cp'
    opfunc = True
    nargs='*'
    op = "eval"
    shorthand = '''normal! mx$?^(\<lt>CR>\\"sy%`x'''

    def prepare_payload(self, *args):
        log.log_info('Evaluating {}'.format(str(args)))

        code = parser.transform(" ".join(args), parser.remove_comment)

        log.log_info('Final code after transform {}'.format(code))

        return {"code": code, "ns": get_acid_ns(self.nvim)}
