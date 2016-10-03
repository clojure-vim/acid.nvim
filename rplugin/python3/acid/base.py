# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import nrepl
from collections import deque

def _connect(port_no):
    return nrepl.connect("nrepl://localhost:{}".format(port_no()))

def _write(ch, op="eval", ns="user", **data):
    data.update({"op": op, "ns": ns})
    ch.write(data)
    return ch

def send(port_no_fn, handler, **data):
    ch = _write(_connect(port_no_fn), **data)

    queue = deque()
    queue.append(data)

    for out in ch:
        queue.append(out)
        if "status" in out:
            break

    handler(queue)
