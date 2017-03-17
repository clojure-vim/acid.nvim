from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Goto'
    nargs = 1
    cmd_name = 'AcidGoto'
    handlers = ['Goto']
    op = "info"
    shorthand_mapping = '<leader>f'

    def shorthand(self):
        iskw = self.nvim.current.buffer.options['iskeyword']
        self.nvim.current.buffer.options['iskeyword'] = \
            ','.join(set(iskw.split(',')) | {"/"})
        data = self.nvim.funcs.expand('<cword>')
        self.nvim.current.buffer.options['iskeyword'] = iskw
        return data

    def prepare_payload(self, mode, *args):
        ns = path_to_ns(self.nvim)
        if mode == 'shorthand':
            data = self.shorthand()
        else:
            data = mode
        return {"symbol": data, "ns": ns}
