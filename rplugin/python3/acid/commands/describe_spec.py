from acid.commands import BaseCommand
from acid.pure.doc_fmt import doc_transform
from acid.nvim import path_to_ns, log

def tf(f):
    if type(f) == list:
        return ', '.join(f)
    return f

definition = {
    'data': {
        'spec-name': {},
        'spec-form': {
            'transform': lambda k: [
                tf(i) for i in k
            ]
        },
    },
    'format': [
        'spec-name',
        [],
        'spec-form'
    ]
}


class Command(BaseCommand):

    name = 'DescribeSpec'
    priority = 0
    nargs = 1
    handlers = ['Doc']
    op = "spec-form"
    shorthand_mapping = 'css'
    shorthand="call setreg('s', expand('<cword>'))"

    def on_configure(self, *_a, **_k):
        log.log_debug('Passing spec transformation fn')
        return [doc_transform(definition)]

    def prepare_payload(self, data):
        return {'spec-name': data}

