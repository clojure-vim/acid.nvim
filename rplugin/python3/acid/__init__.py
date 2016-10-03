# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim

@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim

