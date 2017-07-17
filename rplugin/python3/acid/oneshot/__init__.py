#coding: utf-8
""" Defines one-shot commands

Those don't expose any functionality as commands, but are executed once
a clojure file is loaded (such as `require` or setting alternate file).
"""

class BaseOneShot(object):
    pass
