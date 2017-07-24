from acid.commands import BaseCommand
from acid.nvim import path_to_ns
from acid.pure.doc_fmt import doc_transform
from collections import OrderedDict


definition = {
    'data': OrderedDict([
        ['name', {}],
        ['ns', {'default': ''}],
        ['arglists-str', {
            'default': [],
            'rename': 'fn_calls',
            'transform': lambda t, name: ' '.join([
                '({}{})'.format(name, ' {}'.format(i) if i else '')
                for i in t[2:-2].split('] [')
            ])
        }],
        ['doc', {'default': '', 'transform': lambda k: k.split('\n')}],
        ['javadoc', {'default': ''}],
        ['added', {'default': '', 'transform': 'Since version: {}'.format}],
        ['super', {'default': '', 'transform': 'Extends: {}'.format}],
        ['modifiers', {'default': []}],
        ['see-also', {
            'default': []],
            'transform': lambda k: 'See Also: {}'.format('\n'.join(['', *k]))
        },
        ['interfaces', {
            'default': []],
            'transform': lambda k: 'Implements: {}'.format(', '.join(k))
        }
    ]),
    'format': [
        'fn_calls',
        [],
        'ns',
        'modifiers',
        [],
        'javadoc',
        'doc'
        [],
        'added',
        'interfaces',
        'super',
        'see-also',
    ]
}


class Command(BaseCommand):

    name = 'Doc'
    priority = 0
    nargs = 1
    handlers = ['Doc']
    op = "info"
    shorthand_mapping = 'K'
    shorthand="call setreg('s', expand('<cword>'))"

    def on_configure(self, *_a, **_k):
        return [doc_transform(definition)]

    def prepare_payload(self, data):
        return {"symbol": data, "ns": path_to_ns(self.nvim)}

