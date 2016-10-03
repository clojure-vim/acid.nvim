# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.base import send


def ignore(queue):
    [_ for i in queue]

@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim


    @neovim.function("AcidEval")
    def acid_eval(self, data):
        send(data, ignore)
