
class BaseHandler(object):

    __instances__ = {}
    finalizer = lambda msg, *_: 'status' in msg

    def on_init(self):
        pass

    def on_pre_handle(self):
        pass

    @staticmethod
    def on_handle(*_):
        pass

    @classmethod
    def init_handler(cls, nvim):
        inst = cls(nvim)
        inst.on_init()
        cls.__instances__[cls.name] = inst

    @classmethod
    def pre_handle(cls):
        inst = cls.__instances__[cls.name]
        inst.on_pre_handle()

    @classmethod
    def gen_handler(cls, stop_handler):
        inst = cls.__instances__[cls.name]
        nvim = inst.nvim

        def handler(msg, wc, key):
            try:
                nvim.async_call(lambda: inst.on_handle(msg, wc, key))
            finally:
                if cls.finalizer(msg, wc, key):
                    stop_handler(wc, key)

        return handler
