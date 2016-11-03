from acid.commands import BaseCommand


class Command(BaseCommand):

    name = 'Eval'
    cmd_name = 'AcidEval'
    handlers = ['Proto']
    handlers_var = 'acid_eval_command_handler'
    op = "eval"

    def prepare_payload(self, *args):
        self.nvim.call("inputsave")
        ret = self.nvim.call("input", "acid - eval> ")
        self.nvim.call("inputrestore")
        return {"code": ret}
