from acid.nvim import get_customization_variable, log, convert_case
import functools
import re

opfunc_forwarder = """function! {}OpfuncFw(block)
    call AcidOpfunc('{}', a:block)
endfunction
"""

opfuncfw = lambda k: opfunc_forwarder.format(k, k)
silent_map = lambda *s: "noremap <silent> <buffer> {} {}".format(*s)


def items(col):
    t = type(col)
    if t == dict:
        return col.items()
    if t == str:
        return [col]
    return [[i] for i in  col]


class BaseCommand(object):

    __instances__ = {}
    with_acid = False

    def __init__(self, nvim):
        self.nvim = nvim

    def on_init(self):
        pass

    def prepare_payload(self, *args):
        return {}

    def configure(self, context, handler, *args):
        handler.configure(*args, **context)
        return handler

    def start_handler(self, context, handler, *args):
        return self.configure(context, handler.do_init(), *args)

    @classmethod
    def build_interfaces(cls, nvim):
        cmd = []
        cmd_name = getattr(cls, 'cmd_name')

        if not cmd_name:
            return

        nargs = getattr(cls, 'nargs', 0)
        cmd.append(
            'command! -buffer -nargs={} {} AcidCommand {} {}'.format(
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
            if nargs in [0, '?', '*']:
                cmd.append(silent_map(mapping, ':{}<CR>'.format(cmd_name)))
            elif hasattr(cls, 'prompt'):
                cmd.append(silent_map(mapping, ':{}Prompt<CR>'.format(cmd_name)))

        elif motion_mapping:
            mapping = nvim.vars.get(mapping_var, mapping)
            cmd.append(opfuncfw(cmd_name))
            cmd.append(silent_map(
                mapping, ':set opfunc={}OpfuncFw<CR>g@'.format(cmd_name)
            ))

        if hasattr(cls, 'shorthand'):
            shorthand_mapping = "{}_shorthand_mapping".format(
                convert_case(cmd_name)
            )
            mapping = getattr(
                cls, 'shorthand_mapping',"{}{}".format(
                    mapping, mapping[-1]
                ) if mapping is not None else None
            )
            mapping = nvim.vars.get(shorthand_mapping, mapping)
            shorthand = cls.shorthand
            cmd.append(silent_map(
                mapping, ":call AcidShorthand(\"{}\", \"{}\")<CR>".format(
                    cmd_name, shorthand)
            ))

        if hasattr(cls, 'prompt'):
            prompt = 'command! -buffer -nargs=0 {}Prompt call AcidPrompt("{}")'
            cmd.append(prompt.format(cmd_name, cmd_name))

        return cmd

    @classmethod
    def do_init(cls, nvim):
        inst = cls(nvim)
        inst.on_init()
        aucmd = 'autocmd FileType clojure {}'
        [nvim.command(aucmd.format(v)) for v in cls.build_interfaces(nvim)]
        cls.__instances__[cls.name] = inst

    @classmethod
    def call(cls, acid, context, *args):
        inst = cls.__instances__[cls.name]

        payload = inst.prepare_payload(*args)

        if payload is None:
            return

        if not 'op' in payload:
            payload.update({'op': cls.op})

        handlers_var = "{}_command_handler".format(convert_case(inst.cmd_name))

        custom = get_customization_variable(
            acid.nvim, handlers_var, inst.handlers
        )

        handlers = (
            inst.start_handler(context, context['handlers'].get(h), *args)
            for h, *args in items(custom)
        )

        acid.command(payload, handlers)
