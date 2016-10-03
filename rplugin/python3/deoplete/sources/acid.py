"""Shameless copy from async-clj-omni.

Sorry.
"""
import sys, os

sys.path.append(os.path.dirname(os.path.relpath(__file__)))

from acid_core.base import send
from acid_core.nvim import get_port_no
from .base import Base
import nrepl


short_types = {
    "function": "f",
    "macro": "m",
    "var": "v",
    "special-form": "s",
    "class": "c",
    "keyword": "k",
    "local": "l",
    "namespace": "n",
    "field": "i",
    "method": "f",
    "static-field": "i",
    "static-method": "f",
    "resource": "r"
}


def candidate(val):
    arglists = val.get("arglists")
    type = val.get("type")
    return {
        "word": val.get("candidate"),
        "kind": short_types.get(type, type),
        "info": val.get("doc", ""),
        "menu": " ".join(arglists) if arglists else ""
    }


class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)
        self.name = "acid"
        self.mark = "[acid]"
        self.filetypes = ['clojure']
        self.rank = 200
        self.info("acid init'ed successfully")

    def gather_candidates(self, context):
        def handler(queue):
            completions = filter(lambda k: "completions" in k, queue)
            self.debug("Got back: {}".format(completions))
            return [candidate(j) for j in completions]

        self.debug("Fetching completions on nREPL for {}".format(
            context['complete_str']
        ))

        self.debug("calling send: ".format(acid.base.send))

        return acid.base.send(
            get_port_no,
            handler,
            **{"op": "complete",
               "symbol": context["complete_str"],
               "extra-metadata": ["arglists", "doc"],
               "ns": ns}
        )
