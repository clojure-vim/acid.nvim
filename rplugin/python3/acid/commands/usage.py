from acid.commands import BaseCommand
from acid.nvim import current_file, current_path, path_to_ns

class Command(BaseCommand):

    name = 'FindUsage'
    priority = 0
    cmd_name = 'AcidFindUsage'
    handlers = ['Usage']
    mapping = 'gu'
    with_acid = True
    op = "info"

    def prepare_payload(self, *args):
        data = self.nvim.funcs.expand('<cword>')
        ns = path_to_ns(self.nvim)
        return {"symbol": data, "ns": ns}
