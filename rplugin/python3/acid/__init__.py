# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.base import send


def ignore(queue):
    map(lambda *x: x, queue)


def output_to_window(nvim):

    nvim.command("topleft vertical split | enew")
    bufnr = nvim.current.buffer.number
    buf = nvim.buffers[bufnr]

    def handler(queue):
        map(buf.append, queue)


@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim


    @neovim.function("AcidEval")
    def acid_eval(self, data):
        handler = output_to_window(self.nvim)
        send(self.nvim, data, handler)
