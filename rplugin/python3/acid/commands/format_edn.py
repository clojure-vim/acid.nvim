from acid.commands import BaseCommand
from acid.nvim import get_acid_ns


class Command(BaseCommand):

    name = 'FormatEdn'
    priority = 0
    cmd_name = 'AcidFormatEdn'
    handlers = ['MetaRepl']
    mapping = 'cf'
    opfunc = True
    nargs='*'
    op = "format-edn"

    def prompt(self):
        self.nvim.call("inputsave")
        ret = self.nvim.call("input", "acid - format-edn> ")
        self.nvim.call("inputrestore")
        return ret

    def prepare_payload(self, mode, *args):
        if mode == 'prompt':
            ret = self.prompt()
        elif mode == 'opfunc':
            ret = " ".join(args)
        else:
            ret = " ".join([mode, *args])

        return {'edn': ret, 'pprint-fn': 'clojure.pprint/pprint'}
