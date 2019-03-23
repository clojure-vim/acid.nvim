import os
import re
from acid.nvim.log import log_debug, log_warning


def path_to_ns(path, stop_paths=None, base_files=None):
    log_debug("Supplied path is {}", str(path))

    if not path:
        log_debug("Possibly empty or scratch buffer. Skipping")
        return

    if stop_paths is None:
        stop_paths = ['src', 'test']

    if base_files is None:
        base_files = ['project.clj', 'deps.edn', 'build.boot']

    stop_paths = sorted(stop_paths, key=lambda x: x.count('/'))

    raw_path_list = None

    for stop_path in reversed(stop_paths):
        stop_path = "/{}/".format(stop_path)
        ix = path[::-1].find(stop_path[::-1])
        log_debug("Attempting reverse match: [{}: {}] -> {}",
                  stop_path[::-1], path[::-1], ix)
        if ix > 0:
            startpos = len(path) - ix
            raw_path_list = path[startpos:].replace("_", "-").split('/')
            raw_path_list = [x for x in raw_path_list if x]
            if len(raw_path_list) > 0:
                raw_path_list[-1] = raw_path_list[-1].split('.')[0]
                break

    if raw_path_list is None:
        log_debug("Previous check did not work. Attempting base files")

        # Look for project.clj
        path = path.replace("_", "-").split('/')[1:]
        path[-1] = path[-1].split('.')[0]
        for ix, _ in enumerate(path):
            for bf in base_files:
                if os.path.exists(os.path.join(*["/", *path[:ix], bf])):
                    raw_path_list = path[ix+1:]
                    break

    if not raw_path_list:
        log_warning("Have not found any viable path")
        return ""
    else:
        log_debug("Found path list: {}", raw_path_list)
        return ".".join(raw_path_list)


def ns_to_path(ns):
    return ns.replace("-", "_").replace(".", "/")


def rename_file(cf_name, rename_fn):
    "Takes a filename and a function and renames preserving the extension."

    splitted = cf_name.split('.')
    return '.'.join([rename_fn(splitted[0]), *splitted[1:]])

