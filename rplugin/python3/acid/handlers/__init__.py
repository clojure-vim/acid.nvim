
def status_finalizer(msg, *_):
    return 'status' in msg

class BaseHandler(object):

    finalizer = status_finalizer

    def __repr__(self):
        return "<Handler: {}>".format(self.__class__.name)

    @classmethod
    def do_init(cls, nvim):
        inst = cls(nvim)
        inst.on_init()
        return inst

    def with_matcher(self, matcher):
        self.matcher.update(matcher)

    def __init__(self, nvim):
        self.nvim = nvim
        self.matcher = {}

    def on_init(self):
        pass

    def on_pre_handle(self, *_):
        pass

    def pre_handle(self, *args):
        self.on_pre_handle(*args)

    def on_handle(self, *_):
        pass

    def gen_handler(self, stop_handler):
        nvim = self.nvim
        finalizer = self.__class__.finalizer
        on_handle = self.on_handle

        def handler(msg, wc, key):
            try:
                nvim.async_call(lambda: on_handle(msg, wc, key))
            finally:
                if finalizer(msg, wc, key):
                    stop_handler(wc, key)

        return handler

class SingletonHandler(BaseHandler):

    instances = {}

    def __repr__(self):
        return "<Handler: {}>".format(self.__class__.name)

    @classmethod
    def do_init(cls, nvim):
        if not cls.name in SingletonHandler.instances:
            inst = cls(nvim)
            inst.on_init()
            SingletonHandler.instances[cls.name] = inst
        else:
            inst = SingletonHandler.instances[cls.name]
        return inst

    @classmethod
    def deinit(cls):
        del SingletonHandler.instances[cls.name]
