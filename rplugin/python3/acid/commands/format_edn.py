from acid.commands import BaseCommand
from acid.nvim import get_acid_ns


class Command(BaseCommand):

    name = 'FormatEdn'
    priority = 0
    handlers = ['MetaRepl']
    mapping = 'cfe'
    opfunc = True
    nargs='*'
    op = "format-edn"

    def prepare_payload(self, *args):
        return {'edn': " ".join(args), 'pprint-fn': 'clojure.pprint/pprint'}
