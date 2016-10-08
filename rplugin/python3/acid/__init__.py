# encoding:utf-8
""" Acid stands for Asynchronous Clojure Interactive Development. """
import neovim
from acid.nvim import (
    get_port_no, output_to_window, path_to_ns,
    find_file_in_path
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

    @neovim.function("AcidGoTo")
    def acid_goto(self, data):
        port_no = get_port_no(self.nvim)
        payload = data[0]

        def goto_handler(queue):
            msg = [i for i in queue if 'resource' in i]

            if not msg:
                self.nvim.command("echom 'symbol {} not found'".format(
                    payload
                ))
                return

            msg = msg[0]

            if 'file' in msg:
                f = find_file_in_path(self.nvim, msg)
                self.nvim.command("edit {}".format(f))

            c = msg.get('column', 1)
            l = msg.get('line', 1)

            self.nvim.funcs.cursor(l, c)

        send(port_no, goto_handler, **{"op": "info", "symbol": payload})

    @neovim.command("AcidGoToDefinition")
    def acid_goto_def(self):
        self.nvim.command('normal! "syiw')
        data = self.nvim.funcs.getreg('s')
        self.acid_goto([data])

    @neovim.command("AcidRequire")
    def acid_require(self):
        port_no = get_port_no(self.nvim)
        ns = get_acid_ns(self.nvim)
        data = "(require '[{} :refer :all])".format(path_to_ns(self.nvim))
        send(port_no, ignore, **{"code": data, "ns": ns})
