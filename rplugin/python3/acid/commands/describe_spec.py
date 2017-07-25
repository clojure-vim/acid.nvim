from acid.commands import BaseCommand
from acid.pure.doc_fmt import doc_transform
from acid.nvim import path_to_ns

definition = {
    'data': {
        'spec-name': {},
        'spec-form': {},
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
    enabled = 0
    nargs = 1
    handlers = ['Doc']
    op = "spec-form"
    shorthand_mapping = 'css'
    shorthand="call setreg('s', expand('<cword>'))"

    def on_configure(self, *_a, **_k):
        return [doc_transform(definition)]

    def prepare_payload(self, data):
        return {'spec-name': data}

