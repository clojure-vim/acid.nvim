from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Session'
    nargs = 1
    cmd_name = 'AcidSession'
    handlers = ['SessionAdd']

    def shorthand(self):
        pre = self.nvim.funcs.getreg('s')
        self.nvim.command('normal! "syiw')
        data = self.nvim.funcs.getreg('s')
        self.nvim.funcs.setreg('s', pre)
        return data

    def prepare_payload(self, mode, *args):
        ns = path_to_ns(self.nvim)
        if mode == 'shorthand':
            data = self.shorthand()
        else:
            data = mode
        return {"symbol": data, "ns": ns}

