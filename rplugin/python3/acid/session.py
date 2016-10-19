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

            def log_all(msg, wc, key):
                with open(key, 'a') as out:
                    out.write(str(msg))
                    out.write('\n')

            def clone_handler(msg, wc, key):
                self.sessions[key]['session'] = msg['new-session']
                wc.unwatch(key)

            wconn.watch('/tmp/{}'.format(url.split('/')[-1]), {}, log_all)
            # wconn.watch(url, {'new-session': None}, clone_handler)
            wconn.send({'op': 'clone'})

        return self.sessions[url]['conn']

    def add_atomic_watch(self, url, msg_id, handler, n, matches={}):
        "Adds a callback to a msg_id on a connection."
        watcher_key = "{}-watcher".format(msg_id)
        conn = self.get_or_create(url)

        def finalize_watch(wc, key):
            wc.unwatch(key)

        patched_handler = handler.gen_handler(finalize_watch)

        matches.update({"id": msg_id})
        conn.watch(watcher_key, matches, patched_handler)

        n.command('echom "Watching {} {}"'.format(watcher_key, matches))

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


def send(n, session, address, handler,
         matches={}, op="eval", ns="user", **data):
    msg_id = data.get('id', uuid.uuid4().hex)
    url = "nrepl://{}:{}".format(*address)
    data.update({"op": op, "ns": ns, "id": msg_id})

    n.command('echom "Msg id {}"'.format(msg_id))
    session.add_atomic_watch(url, msg_id, handler, n, matches)
    session.send(url, data)
