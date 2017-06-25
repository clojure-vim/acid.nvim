from acid.commands import BaseCommand
from acid.nvim import current_file, current_path
import os


class Command(BaseCommand):

    name = 'Rename'
    priority = 0
    nargs = 1
    handlers = ['MvSingle']
    prompt = 1
    op = "rename-file-or-dir"

    def prepare_payload(self, path):
        current = current_file(self.nvim)
        root = current_path(self.nvim)
        new = path.replace('-', '_').split('.')
        new[-1] = '{}.{}'.format(new[-1], current.split('.')[-1])
        final = os.path.join(root, 'src', *new)
        return {"old-path": current, "new-path": final}

