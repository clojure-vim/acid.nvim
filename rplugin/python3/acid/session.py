# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.relpath(__file__)))

import nrepl
import uuid


class SessionHandler(object):

    def __init__(self):
        self.sessions = {}

    def get_or_create(self, url):
        if url not in self.sessions:
            conn = nrepl.connect(url)
            wconn = nrepl.WatchableConnection(conn)

            self.sessions[url] = {
                'conn': wconn
            }

            def clone_handler(msg, wc, key):
                self.sessions[key]['session'] = msg['new-session']
                wc.unwatch(key)

            wconn.watch(url, {'new-session': None}, clone_handler)
            wconn.send({'op': 'clone'})

        return self.sessions[url]['conn']

    def add_atomic_watch(self, url, msg_id, handler, matches={}):
        "Adds a callback to a msg_id on a connection."
        watcher_key = "{}-watcher".format(msg_id)
        conn = self.get_or_create(url)

        def finalize_watch(wc, key):
            wc.unwatch(key)

        patched_handler = handler.gen_handler(finalize_watch)

        matches.update({"id": msg_id})
        conn.watch(watcher_key, matches, patched_handler)

        handler.pre_handle()

    def send(self, url, data):
        conn = self.get_or_create(url)

        if 'session' in self.sessions[url]:
            data.update({"session": self.sessions[url]['session']})

        try:
            conn.send(data)
        except:
            conn.close()
            del self.sessions[url]


def send(session, address, handlers, data):
    url = "nrepl://{}:{}".format(*address)

    msg_id = data.get('id', uuid.uuid4().hex)
    data.update({"id": msg_id})

    for i in handlers:
        handler, match = i
        session.add_atomic_watch(url, msg_id, handler, match)

    session.send(url, data)
