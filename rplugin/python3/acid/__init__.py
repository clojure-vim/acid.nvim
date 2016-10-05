# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    get_port_no, output_to_window, path_to_ns
)
from acid.base import send


def ignore(queue):
    pass


@neovim.plugin
class Acid(object):

    def __init__(self, nvim):
        self.nvim = nvim

    @neovim.function("AcidEval")
    def acid_eval(self, data):
        handler = output_to_window(self.nvim)
        port_no = get_port_no(self.nvim)
        send(port_no, handler, **data[0])

    @neovim.command("AcidRequire")
    def acid_require(self):
        port_no = get_port_no(self.nvim)
        ns = get_acid_ns(self.nvim)
        data = "(require '[{} :refer :all])".format(path_to_ns(self.nvim))
        send(port_no, ignore, **{"code": data, "ns": ns})
