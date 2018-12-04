from acid.handlers import BaseHandler
from acid.nvim.log import error


class Handler(BaseHandler):

    name = "LuaFn"
    priority = 0

    def on_init(self):
        self.lua_fn = ""

    def configure(self, lua_fn, *args, **kwargs):
        super().configure(*args, **kwargs)
        self.lua_fn = lua_fn
        return self

    def on_handle(self, msg, *_):
            self.nvim.funcs.luaeval(self.lua_fn, msg)
