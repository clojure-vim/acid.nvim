from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Goto'
    cmd_name = 'AcidGoToDefinition'
    handlers = ['Goto']
    handlers_var = 'acid_goto_command_handler'
    op = "info"
    mapping = '<leader>f'

    def prepare_payload(self, *args):
        self.nvim.command('normal! "syiw')
        data = self.nvim.funcs.getreg('s')
        ns = path_to_ns(self.nvim)
        return {"symbol": data, "ns": ns}
