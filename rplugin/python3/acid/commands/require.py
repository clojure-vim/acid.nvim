from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Require'
    cmd_name = 'AcidRequire'
    handlers = ['Ignore']
    handlers_var = 'acid_require_command_handler'
    op = "eval"
    mapping = '<leader>ar'

    def on_init(self):
        self.required_cache = {}

    def prepare_payload(self, *args):
        ns = path_to_ns(self.nvim)
        code = "(require '[{}] :reload)"
        return {"code": code}

