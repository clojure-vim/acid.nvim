# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import nrepl
from collections import deque

def _connect(port_no=None):
    if not port_no:
        with open(".nrepl-port") as port:
            port_no = port.read().strip()

    return nrepl.connect("nrepl://localhost:{}".format(port_no))

def _write(ch, data, ns="user"):
    ch.write({"op": "eval", "code": data, "ns": ns})
    return ch


def send(data, handler):
    ch = _write(_connect(), data)

    queue = deque()
    queue.append({"in": data})

    for out in ch:
        queue.append(out)

    queue.reverse()

    handler(queue)

