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


def current_file(nvim):
    return nvim.funcs.expand("%:p")

def current_path(nvim):
    return nvim.funcs.getcwd()

def path_to_ns(nvim):
    path = nvim.funcs.expand("%:r")
    return ".".join(path.split('/')[1:]).replace("_","-")


def get_port_no(nvim):
    pwd = nvim.funcs.getcwd()

    with open(os.path.join(pwd, ".nrepl-port")) as port:
        return port.read().strip()


def localhost(nvim):
    host = nvim.vars.get('acid_lein_host', '127.0.0.1')
    try:
        return [host, get_port_no(nvim)]
    except:
        return None

def formatted_localhost_address(nvim):
    addr = localhost(nvim)
    if addr:
        return "{}://{}:{}".format('nrepl', *addr)
    else:
        return None


def get_acid_ns(nvim):
    strategy = nvim.current.buffer.vars.get(
        'acid_ns_strategy', nvim.vars.get('acid_ns_strategy', 'global')
    )
    if strategy == 'buffer':
        return path_to_ns(nvim)
    elif strategy == 'global':
        return 'user'
    elif 'ns:' in strategy:
        return strategy.split(':')[-1]



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

    if os.path.exists(fpath):
        return fpath
    elif 'resource' in msg:
        resource = msg['resource']
        alt_paths = nvim.vars.get('acid_alt_paths', [])
        paths = ['src', 'test', *alt_paths]

        for path in paths:
            attempt = os.path.join(path, resource)
            if os.path.exists(attempt):
                return attempt

        project = resource.split('/')[0]
        foreign_project_fpath = nvim.vars.get('acid_project_root', None)
        if foreign_project_fpath is None:
            return

        for path in paths:
            attempt = os.path.join(foreign_project_f, project, path, resource)
            if os.path.exists(attempt):
                return attempt

        if os.path.exists(foreign_project_fpath):
            return foreign_project_fpath
