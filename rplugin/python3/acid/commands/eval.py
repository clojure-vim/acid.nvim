from acid.commands import BaseCommand


class Command(BaseCommand):

    name = 'Eval'
    cmd_name = 'AcidEval'
    handlers = ['Proto']
    mapping = 'cp'
    opfunc = True
    nargs='*'
    op = "eval"

    def prompt(self):
        self.nvim.call("inputsave")
        ret = self.nvim.call("input", "acid - eval> ")
        self.nvim.call("inputrestore")
        return ret

    def shorthand(self):
        cmd = '''exec 'normal! mx$?^("sy%`x' | nohl'''
        self.nvim.command(cmd)
        return self.nvim.funcs.getreg('s')

    def prepare_payload(self, mode, *args):
        if mode == 'shorthand':
            ret = self.shorthand()
        elif mode == 'prompt':
            ret = self.prompt()
        elif mode == 'opfunc':
            ret = " ".join(args)
        else:
            ret = " ".join([mode, *args])

        return {"code": ret}
