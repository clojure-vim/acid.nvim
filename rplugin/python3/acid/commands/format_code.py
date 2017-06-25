from acid.commands import BaseCommand
from acid.nvim import get_acid_ns


class Command(BaseCommand):

    name = 'FormatCode'
    priority = 0
    handlers = ['MetaRepl']
    mapping = 'cfc'
    shorthand = '''normal! mx$?^(\<lt>CR>\\"sy%`x'''
    opfunc = True
    nargs='*'
    op = "format-code"

    def prepare_payload(self, *args):
        return {'code': " ".join(args), }
