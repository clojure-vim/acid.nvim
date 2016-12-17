from acid.session import send

def status_finalizer(msg, *_):
    return 'status' in msg

class BaseHandler(object):

    finalizer = status_finalizer

    def __repr__(self):
        return "<Handler: {}>".format(self.__class__.name)

    @classmethod
    def do_init(cls):
        inst = cls()
        inst.on_init()
        return inst

    def with_matcher(self, matcher):
        self.matcher.update(matcher)

    def __init__(self):
        self.matcher = {}

    def configure(self, *args, **kwargs):
        self.nvim = kwargs['nvim']
        self.handlers = kwargs['handlers']
        return self

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
    def do_init(cls):
        if not cls.name in SingletonHandler.instances:
            inst = cls()
            inst.on_init()
            SingletonHandler.instances[cls.name] = inst
        else:
            inst = SingletonHandler.instances[cls.name]
        return inst

    @classmethod
    def deinit(cls):
        del SingletonHandler.instances[cls.name]

class WithFSM(BaseHandler):

    initial_state = "init"

    def __repr__(self):
        return "<FSMHandler: {} on state {}>".format(
            self.__class__.name, self.current_state
        )

    def on_init(self):
        self.current_state = self.initial_state
        self.current_handler_fn = self.handle_init
        return self

    def configure(self, *args, **kwargs):
        super().configure(*args, **kwargs)
        self.session_handler = kwargs['session_handler']
        self.url = kwargs['url']
        return self

    def change_state(self, new_state, payload, *handlers):
        handlers = list(handlers)
        handlers.append(self)
        send(self.session_handler, self.url, handlers, payload)
        self.current_state = new_state
        self.current_handler_fn = getattr(
            self,
            'handle_{}'.format(new_state),
            lambda *args, **kwargs: None
        )

    def on_handle(self, msg, wc, key):
        self.current_handler_fn(msg, wc, key)
