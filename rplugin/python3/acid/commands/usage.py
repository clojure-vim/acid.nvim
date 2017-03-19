from acid.commands import BaseCommand
from acid.nvim import current_file, current_path, path_to_ns

class Command(BaseCommand):

    name = 'FindUsage'
    priority = 0
    cmd_name = 'AcidFindUsage'
    handlers = ['Usage']
    with_acid = True
    op = "info"
    shorthand_mapping = 'gu'
    shorthand="call setreg('s', expand('<cword>'))"

    def prepare_payload(self, *args):
        return {"symbol": " ".join(args), "ns": path_to_ns(self.nvim)}
