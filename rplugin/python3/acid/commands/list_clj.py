from acid.commands import BaseCommand
from acid.nvim import list_clj_files
import os

def transform_path_to_ns(path):
    return os.path.splitext(os.path.basename(path))[0].replace('_', '-')

class Command(BaseCommand):

    name = 'ListClj'
    priority = 0
    enabled = 0
    nargs = 0
    handlers = []
    mapping = 'clf'

    def prepare_payload(self, ns):
        clj_files = [i for i in list_clj_files(self.nvim)]
