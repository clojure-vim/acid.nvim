import os
import re
from acid.nvim.log import log_debug, log_warning


def path_to_ns(path, stop_paths=None):
    if stop_paths is None:
        stop_paths = ['src', 'test']

    stop_paths = sorted(stop_paths, key=lambda x: x.count('/'))

    raw_path_list = None

    for stop_path in reversed(stop_paths):
        m = re.search(stop_path[::-1], path[::-1])
        if m:
            startpos = len(path) - m.start()
            raw_path_list = path[startpos:].replace("_", "-").split('/')
            raw_path_list = [x for x in raw_path_list if x]
            raw_path_list[-1] = raw_path_list[-1].split('.')[0]
            break

    if raw_path_list is None:
        log_debug("Previous check did not work. Attempting project.clj")

        # Look for project.clj
        path = path.replace("_", "-").split('/')[1:]
        path[-1] = path[-1].split('.')[0]
        for ix, _ in enumerate(path):
            if os.path.exists(os.path.join(*["/", *path[:ix], "project.clj"])):
                raw_path_list = path[ix+1:]
                break

    if raw_path_list is None:
        log_warning("Have not found any viable path")
        return None
    else:
        log_debug("Found path list: {}", raw_path_list)
        return ".".join(raw_path_list)


def ns_to_path(ns):
    return ns.replace("-", "_").replace(".", "/")


def rename_file(cf_name, rename_fn):
    "Takes a filename and a function and renames preserving the extension."

    splitted = cf_name.split('.')
    return '.'.join([rename_fn(splitted[0]), *splitted[1:]])

