from acid.commands import BaseCommand
from acid.nvim import get_acid_ns


class Command(BaseCommand):

    name = 'ExpandMacro'
    priority = 0
    cmd_name = 'AcidExpandMacro'
    handlers = ['MetaRepl']
    mapping = 'cme'
    shorthand = '''normal! mx$?^(\<lt>CR>\\"sy%`x'''
    opfunc = True
    nargs='*'
    op = "macroexpand"

    def prepare_payload(self, *args):
        return {'code': "'{}".format(" ".join(args)),
                'expander': 'macroexpand-all'}
