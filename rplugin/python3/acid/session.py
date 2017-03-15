# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.relpath(__file__)))

import nrepl
import uuid

import logging
from collections import defaultdict

logger = logging.getLogger(__name__)
fh = logging.FileHandler('/tmp/acid-sessions.log')
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
fh.setFormatter(formatter)
logger.addHandler(fh)
logger.setLevel(logging.DEBUG)


def finalize_watch(wc, key):
    wc.unwatch(key)


class SessionHandler(object):

    def __init__(self):
        self.sessions = {}
        self.persistent = defaultdict(set)

    def get_or_create(self, url):
        if url not in self.sessions:
            conn = nrepl.connect(url)
            wconn = nrepl.WatchableConnection(conn)

            self.sessions[url] = {
                'conn': wconn
            }

        return self.sessions[url]['conn']


    def add_persistent_watch(self, url, handler, matches={}):
        "Adds a callback to all messages in a connection."
        watcher_key = "{}-persistent".format(handler.name)
        conn = self.get_or_create(url)

        if not watcher_key in self.persistent[url]:
            logger.info('Adding new persisntent watcher fn: {}'.format(
                handler.name
            ))

            self.persistent[url].add(watcher_key)

            logger.debug('persistent handler -> {}'.format(str(handler)))
            logger.debug('connection -> {}'.format(str(url)))
            logger.debug('key -> {}'.format(str(watcher_key)))

            patched_handler = handler.gen_handler(finalize_watch)
            conn.watch(watcher_key, matches, patched_handler)
        else:
            logger.info('Persisntent watcher fn exists, skipping: {}'.format(
                handler.name
            ))



    def add_atomic_watch(self, url, msg_id, handler, matches={}):
        "Adds a callback to a msg_id on a connection."
        watcher_key = "{}-{}-watcher".format(msg_id, handler.name)
        conn = self.get_or_create(url)

        logger.info('handler -> {}'.format(str(handler)))
        logger.info('connection -> {}'.format(str(url)))
        logger.info('matchers -> {}'.format(str(matches)))
        logger.info('key -> {}'.format(str(watcher_key)))

        patched_handler = handler.gen_handler(finalize_watch)

        # Avoid side-effects
        matches = matches.copy()
        matches.update({"id": msg_id})

        conn.watch(watcher_key, matches, patched_handler)
        try:
            handler.pre_handle(msg_id, url)
        except Exception as e:
            logger.error('Err: could not pre-handler -> {}'.format(str(e)))

    def send(self, url, data, handlers):
        conn = self.get_or_create(url)
        logger.info('sending data -> {}'.format(str(data)))

        for handler in handlers:
            logger.info('passing data to handler {}'.format(str(handler)))
            handler.pre_send(data)

        try:
            conn.send(data)
        except:
            conn.close()
            del self.sessions[url]


def send(session, url, handlers, data):
    msg_id = data.get('id', uuid.uuid4().hex)
    data.update({"id": msg_id})

    handlers = list(handlers)

    logger.info("handlers = {}".format(handlers))
    for handler in handlers:
        session.add_atomic_watch(url, msg_id, handler, handler.matcher)

    session.send(url, data, handlers)
