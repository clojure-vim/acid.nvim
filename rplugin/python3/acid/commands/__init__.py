import functools
import re

opfunc_forwarder = """function! {}OpfuncFw(block)
    call AcidOpfunc('{}', a:block)
endfunction
"""

opfuncfw = lambda k: opfunc_forwarder.format(k, k)

def convert_case(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

class BaseCommand(object):

    __instances__ = {}
    handlers = ['']
    with_acid = False

    def __init__(self, nvim):
        self.nvim = nvim
        handlers_var = "{}_command_handler".format(convert_case(self.cmd_name))
        handlers = self.handlers

        if handlers_var is not '':
            self.actual_handlers = self.nvim.vars.get(handlers_var, handlers)
        else:
            self.actual_handlers = handlers

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
    def build_interfaces(cls, nvim):
        cmd = []
        cmd_name = getattr(cls, 'cmd_name')

        if cmd_name:
            nargs = getattr(cls, 'nargs', 0)
            cmd.append(
                'command! -nargs={} {} AcidCommand {} {}'.format(
                    nargs,
                    cmd_name,
                    cls.name,
                    (nargs != '0' and '<args>' or '')
                )
            )

        mapping_var = "{}_command_mapping".format(convert_case(cmd_name))
        mapping = getattr(cls, 'mapping', None)
        opfunc = getattr(cls, 'opfunc', False)
        default_mapping = mapping is not None and not opfunc
        motion_mapping = mapping is not None and opfunc


        if default_mapping:
            mapping = nvim.vars.get(mapping_var, mapping)
            cmd.append('noremap {} :{}<CR>'.format(mapping, cmd_name))
        elif motion_mapping:
            mapping = nvim.vars.get(mapping_var, mapping)
            cmd.append(opfuncfw(cmd_name))
            cmd.append('noremap {} :set opfunc={}OpfuncFw<CR>g@'.format(
                mapping, cmd_name
            ))

        if hasattr(cls, 'shorthand'):
            shorthand_mapping = "{}_shorthand_mapping".format(
                convert_case(cmd_name)
            )
            mapping = nvim.vars.get(
                shorthand_mapping, "{}{}".format(mapping, mapping[-1])
            )
            cmd.append('noremap {} :{} shorthand<CR>'.format(
                mapping, cmd_name
            ))

        if hasattr(cls, 'prompt'):
            cmd.append(
                'command! -nargs=0 {}Prompt AcidCommand {} prompt'.format(
                    cmd_name,
                    cls.name
                )
            )

        return cmd

    @classmethod
    def do_init(cls, nvim):
        inst = cls(nvim)
        inst.on_init()
        [nvim.command(cmd) for cmd in cls.build_interfaces(nvim)]
        cls.__instances__[cls.name] = inst

    @classmethod
    def call(cls, acid, context, *args):
        inst = cls.__instances__[cls.name]

        payload = inst.prepare_payload(*args)

        if payload is None:
            return

        if not 'op' in payload:
            payload.update({'op': cls.op})

        get_handler = context['handlers'].get
        start_handler = functools.partial(inst.start_handler, context)

        handler_classes = map(get_handler, inst.actual_handlers)
        handlers = map(start_handler, handler_classes)

        acid.command(payload, handlers)
