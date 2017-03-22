from acid.commands import BaseCommand
from acid.nvim import get_acid_ns, find_clojure_fn
import os


class Command(BaseCommand):

    name = 'AddHotload'
    priority = 0
    cmd_name = 'AcidHotload'
    handlers = ['Ignore']
    nargs = 0
    op = "ns-load-all"

    def prepare_payload(self, *args):
        return {}
