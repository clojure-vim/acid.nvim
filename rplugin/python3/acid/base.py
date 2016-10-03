# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import nrepl
from os.path import join as join_path
from collections import deque

def _port_no(nvim):
    pwd = nvim.funcs.getcwd()
    with open(join_path(pwd, ".nrepl-port")) as port:
        return port.read().strip()

def _connect(nvim):
    return nrepl.connect("nrepl://localhost:{}".format(_port_no(nvim)))

def _write(ch, data, ns="user"):
    ch.write({"op": "eval", "code": data, "ns": ns})
    return ch


def send(nvim, data, handler):
    ch = _write(_connect(port_no), data)

    queue = deque()
    queue.append({"in": data})

    for out in ch:
        queue.append(out)

    queue.reverse()

    handler(queue)

