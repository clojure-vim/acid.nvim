# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.relpath(__file__)))

import nrepl
import uuid

from collections import defaultdict
from acid.nvim import log

def finalize_watch(_, wc, key):
    wc.unwatch(key)
    log.log_info("stopped watching key {}", key)

class SessionHandler(object):

    def __init__(self, default_handler = None):
        self.sessions = {}
        self.persistent = defaultdict(set)
        self.default_handler = default_handler

    def get_or_create(self, url):
        if url not in self.sessions:
            conn = nrepl.connect(url)
            wconn = nrepl.WatchableConnection(conn)
            if self.default_handler is not None:
                watcher_key = "{}-watcher".format(uuid.uuid4().hex)
                wconn.watch(watcher_key, {}, self.default_handler)
                self.default_handler({"wc": watcher_key}, None, None)

            self.sessions[url] = {
                'conn': wconn
            }

        return self.sessions[url]['conn']

    def add_atomic_watch(self, url, msg_id, gen_handler, matches={}):
        "Adds a callback to a msg_id on a connection."
        watcher_key = "{}-{}-watcher".format(msg_id, uuid.uuid4().hex)
        conn = self.get_or_create(url)

        handler = gen_handler(finalize_watch)

        # Avoid side-effects
        matches = matches.copy()
        matches.update({"id": msg_id})

        conn.watch(watcher_key, matches, handler)

    def send(self, url, data, handlers):
        conn = self.get_or_create(url)
        log.log_info('sending data -> {}', str(data))

        try:
            conn.send(data)
        except e:
            log.log_error(e)
            conn.close()
            del self.sessions[url]


def send(session, url, handlers, data, matcher={}):
    msg_id = data.get('id', uuid.uuid4().hex)
    data.update({"id": msg_id})

    handlers = list(handlers)

    for handler in handlers:
        session.add_atomic_watch(url, msg_id, handler, matcher)

    session.send(url, data, handlers)
