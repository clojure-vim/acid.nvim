# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    get_port_no, output_to_window
)
from acid.base import send

def ignore(queue):
    map(lambda *x: x, queue)

@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim

    @neovim.function("AcidEval", sync=False)
    def acid_eval(self, data):
        handler = output_to_window(self.nvim)
        port_no = get_port_no(self.nvim)
        send(port_no, handler, **data[0])
