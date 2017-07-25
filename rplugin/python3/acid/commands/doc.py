from acid.commands import BaseCommand
from acid.nvim import path_to_ns, log
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
        ['doc', {
            'default': '',
            'transform': lambda k: [i.strip() for i in k.split('\n')]
        }],
        ['javadoc', {'default': ''}],
        ['added', {'default': '', 'transform': 'Since version: {}'.format}],
        ['super', {'default': '', 'transform': 'Extends: {}'.format}],
        ['modifiers', {'default': []}],
        ['see-also', {
            'default': [],
            'prepend': 'See Also:',
            'transform': lambda k: [
                'https://clojuredocs.org/{}'.format(i)
                for i in k
            ]
        }],
        ['interfaces', {
            'default': [],
            'transform': lambda k: 'Implements: {}'.format(', '.join(k))
        }]
    ]),
    'format': [
        'fn_calls',
        [],
        'ns',
        'modifiers',
        [],
        'javadoc',
        'doc',
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
        log.log_debug('Passing doc transformation fn')
        return [doc_transform(definition)]

    def prepare_payload(self, data):
        return {"symbol": data, "ns": path_to_ns(self.nvim)}

