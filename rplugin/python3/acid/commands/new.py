from acid.commands import BaseCommand
from acid.nvim import current_path
from acid.pure import ns_to_path, path_to_ns
from acid.nvim.log import warning
import os


class Command(BaseCommand):

    name = 'NewFile'
    priority = 0
    nargs=1
    prompt=1
    handlers = {'Ignore': ''}
    mapping = '<leader>N'

    @staticmethod
    def prompt_default(nvim):
        path = nvim.funcs.expand('%:p:h')
        return "{}.".format(path_to_ns(path))


    def prepare_payload(self, ns):
        fname = "{}.clj".format(ns_to_path(ns))
        base = 'test' if ns.endswith('-test') else 'src'
        open_with = nvim.vars.get('acid_open_new_file_with', 'edit')
        path = os.path.join(current_path(self.nvim), base, fname)

        with open(path, 'w') as fpath:
            fpath.write('(ns {})'.format(ns))

        self.nvim.command('silent {} {}'.format(open_with, path))

        # Does not interact with nrepl
        return None
