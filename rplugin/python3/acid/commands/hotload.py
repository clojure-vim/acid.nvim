from acid.commands import BaseCommand
from acid.nvim import get_acid_ns, find_clojure_fn
import os


class Command(BaseCommand):

    name = 'LoadAll'
    priority = 0
    handlers = {'Ignore': '', 'DoAutocmd': 'AcidLoadedAll'}
    nargs = 0
    op = "ns-load-all"

    def prepare_payload(self, *args):
        return {}
