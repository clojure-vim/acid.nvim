from acid.commands import BaseCommand
from acid.nvim import (
    current_file, current_path, test_paths, src_paths
)
from acid.nvim.log import log_info, log_debug
from acid.pure import path_to_ns

from acid.pure import rename_file
import os

def to_alt_path(path_arr, alt_paths, root, rename_fn, default):
    # clone array so we don't overwrite last element
    path = list(path_arr)[1:]
    path[-1] = rename_file(path[-1], rename_fn)

    for ap in alt_paths:
        fname = os.path.join(root, ap, *path)
        if os.path.exists(fname):
            log_debug("Alternate file exists. using '{}'", fname)
            return fname


    fname = os.path.join(root, default, *path)
    log_debug("Alternate doesn't exist. using '{}'", fname)
    # Returns default path if no test is found
    return fname


class Command(BaseCommand):

    name = 'AlternateFile'
    mapping = '<C-^>'
    nargs = 0
    handlers = []
    priority = 0

    def prepare_payload(self):
        src = src_paths(self.nvim)
        test = test_paths(self.nvim)
        path = current_file(self.nvim)
        root_path = current_path(self.nvim)
        rel_path = os.path.relpath(path, start=root_path).split('/')

        if rel_path[0] in src:
            log_debug("Current file is a 'src', changing to 'test'")
            alt_path = to_alt_path(
                rel_path, test, root_path,
                lambda f: '{}_test'.format(f),
                'test'
            )
        else:
            log_debug("Current file is a 'test', changing to 'src'")
            alt_path = to_alt_path(
                rel_path, src, root_path,
                lambda f: f.split('_')[0],
                'src'
            )

        if os.path.exists(alt_path):
            self.nvim.command('edit {}'.format(alt_path))
        else:
            ns = path_to_ns(alt_path, test | src)
            self.nvim.command('AcidNewFile {}'.format(ns))


        return None
