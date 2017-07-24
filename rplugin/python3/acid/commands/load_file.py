from acid.commands import BaseCommand
from acid.nvim import list_clj_files, current_path
from acid.pure import ns_to_path
import os


class Command(BaseCommand):

    name = 'LoadFile'
    priority = 0
    enabled = 0
    handlers = ['Ignore']
    nargs = 1
    prompt = 1
    op = "load-file"

    def prepare_payload(self, ns):
        files = list_clj_files(self.nvim)
        path = '{}.clj'.format(ns_to_path(ns))

        match = list(filter(lambda k: k.endswith(path), files))
        if any(match):
            fpath, *_ = match
            fpath = os.path.relpath(fpath, start=current_path(nvim))
            with open(fpath, 'r') as source:
                data = '\n'.join(source.readlines())

            return {
                'file': data,
                'file-path': fpath,
                'file-name': os.path.basename(fpath)
            }
