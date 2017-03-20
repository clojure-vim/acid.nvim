from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Require'
    priority = 0
    nargs='*'
    cmd_name = 'AcidRequire'
    handlers = ['Ignore']
    op = "eval"
    mapping = 'caR'
    shorthand_mapping = 'car'
    shorthand = 'normal! \\"syi]'

    def on_init(self):
        self.required_cache = {}

    def prepare_payload(self, *args):
        if len(args) == 0:
            ns = path_to_ns(self.nvim)
            if ns is None:
                self.nvim.command(
                    'echom "Acid: Unable to require. '
                    'Source code outside project"'
                )
                return None
        else:
            ns = " ".join(args)

        return {"code": "(require '[{}] :reload)".format(ns)}

