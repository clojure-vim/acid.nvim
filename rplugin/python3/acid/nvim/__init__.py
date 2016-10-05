from os.path import join as join_path


def path_to_ns(nvim):
    path = nvim.funcs.expand("%:r")
    return ".".join(path.split('/')[1:])


def get_port_no(nvim):
    pwd = nvim.funcs.getcwd()

    def fn():
        with open(join_path(pwd, ".nrepl-port")) as port:
            return port.read().strip()

    return fn


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

