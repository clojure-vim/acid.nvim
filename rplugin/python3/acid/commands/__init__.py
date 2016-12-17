import functools

class BaseCommand(object):

    __instances__ = {}
    handlers = ['']
    with_acid = False
    handlers_var = ''

    def __init__(self, nvim):
        self.nvim = nvim
        if self.handlers_var is not '':
            self.actual_handlers = self.nvim.vars.get(
                self.handlers_var, self.handlers
            )
        else:
            self.actual_handlers = self.handlers

    def on_init(self):
        pass

    def prepare_payload(self, *args):
        return {}

    def configure(self, context, handler):
        handler.configure(**context)
        return handler

    def start_handler(self, context, handler):
        return self.configure(context, handler.do_init())

    @classmethod
    def build_interfaces(cls):
        cmd = {'command!': '{} AcidCommand {}'.format(cls.cmd_name, cls.name)}

        mapping = getattr(cls, 'mapping', None)

        if mapping is not None:
            cmd['noremap'] = '{} :{}<CR>'.format(mapping, cls.cmd_name)

        return cmd

    @classmethod
    def do_init(cls, nvim):
        inst = cls(nvim)
        inst.on_init()
        [nvim.command('{} {}'.format(k, v))
         for k, v
         in cls.build_interfaces().items()]
        cls.__instances__[cls.name] = inst

    @classmethod
    def call(cls, context):
        inst = cls.__instances__[cls.name]

        payload = inst.prepare_payload()

        if not 'op' in payload:
            payload.update({'op': cls.op})

        get_handler = context['handlers'].get

        handler_classes = map(get_handler, inst.actual_handlers)
        handlers = map(inst.start_handler, handler_classes)

        acid.command(payload, handlers)
