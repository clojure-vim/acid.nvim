import os
import glob
import sys
from importlib.machinery import SourceFileLoader


def find_extensions(nvim, source):
    """Search for base.py or *.py

    Searches $VIMRUNTIME/*/rplugin/python3/acid/$source[s]/
    """
    rtp = nvim.options.get('runtimepath', '').split(',')

    if not rtp:
        return

    sources = (
        os.path.join('rplugin/python3/acid', source, '*.py'),
    )

    for src in sources:
        for path in rtp:
            yield from glob.iglob(os.path.join(path, src))


def import_extensions(path, source, classname):
    """Import Acid plugin source class.

    If the class exists, add its directory to sys.path.
    """
    name = os.path.splitext(os.path.basename(path))[0]
    module_name = 'acid.%s.%s' % (source, name)
    module = SourceFileLoader(module_name, path).load_module()
    cls = getattr(module, classname, None)

    if not cls:
        return None

    dirname = os.path.dirname(path)

    if dirname not in sys.path:
        sys.path.insert(0, dirname)

    return cls


def path_to_ns(nvim):
    path = nvim.funcs.expand("%:r")
    return ".".join(path.split('/')[1:]).replace("_","-")


def get_port_no(nvim):
    pwd = nvim.funcs.getcwd()

    with open(os.path.join(pwd, ".nrepl-port")) as port:
        return port.read().strip()


def localhost(nvim):
    try:
        return ['127.0.0.1', get_port_no(nvim)]
    except:
        return None


def get_acid_ns(nvim):
    return nvim.vars.get('acid_namespace', 'user')


def with_async(nvim):
    def wrapper(fn):
        def wrapped(*args, **kwargs):
            return nvim.async_call(lambda: fn(*args, **kwargs))
        return wrapped
    return wrapper


def format_payload(payload):
    if type(payload) == str:
        return [payload]

    ls = []
    try:
        for k, v in payload.items():
            key = k.lower()
            if key not in {'ns', 'session', 'id'}:
                if '\n' in v:
                    header, *trailer = v.split('\n')
                else:
                    header,  trailer = v, []
                ls.append("[{: <9}] => {}".format(
                    key.upper(), str(header)
                ).strip())

                for i in trailer:
                    ls.append("{: <14} {}".format("", str(i)))
    finally:
        return ls

def find_file_in_path(nvim, msg):
    fname = msg['file']
    fpath = fname.split(':')[-1]
    project = msg['resource'].split('/')[0]
    foreign_project_fpath = os.path.join(
        nvim.vars.get('acid_project_root', ''),
        project, 'src', msg['resource']
    )

    if os.path.exists(fpath):
        return fpath
    elif os.path.exists(foreign_project_fpath):
        return foreign_project_fpath
