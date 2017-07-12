from acid.commands import BaseCommand
from acid.nvim import path_to_ns


class Command(BaseCommand):

    name = 'Session'
    priority = 0
    op = 'clone'
    handlers = ['SessionAdd']

    def prepare_payload(self, *args):
        return {}

