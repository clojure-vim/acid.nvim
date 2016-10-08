import os


def path_to_ns(nvim):
    path = nvim.funcs.expand("%:r")
    return ".".join(path.split('/')[1:])


def get_port_no(nvim):
    pwd = nvim.funcs.getcwd()

    def fn():
        with open(os.path.join(pwd, ".nrepl-port")) as port:
            return port.read().strip()

    return fn

def get_acid_ns(nvim):
    return nvim.vars.get('acid_namespace', 'user')


def format_payload(payload):
    if type(payload) == str:
        return [payload]

    ls = []
    for k, v in payload.items():
        key = k.upper()
        if key not in {"SESSION", "NS"}:
            ls.append("[{: <9}] => {}".format(key, v).strip())
    return ls

def output_to_window(nvim):

    nvim.command("topleft vertical split | enew")
    bufnr = nvim.current.buffer.number
    buf = nvim.buffers[bufnr]

    def handler(queue):
        [buf.append(j) for i in queue for j in format_payload(i)]

    return handler


def find_file_in_path(nvim, msg):
    fname = msg['file']

    # Not supporting jars at the moment.
    if 'jar:' in fname:
        return

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
