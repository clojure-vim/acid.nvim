# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.base import send


def ignore(queue):
    map(lambda *x: x, queue)


@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim


    @neovim.function("AcidEval")
    def acid_eval(self, data):

        send(self.nvim, data, ignore)
