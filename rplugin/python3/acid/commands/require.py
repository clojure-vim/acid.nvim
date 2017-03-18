from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Require'
    priority = 0
    cmd_name = 'AcidRequire'
    handlers = ['Ignore']
    op = "eval"
    mapping = '<leader>ar'

    def on_init(self):
        self.required_cache = {}

    def prepare_payload(self, *args):
        ns = path_to_ns(self.nvim)
        if ns is None:
            return None

        code = "(require '[{}] :reload)".format(ns)
        return {"code": code}

