from acid.handlers import BaseHandler, WithFSM
from acid.nvim import current_file, current_path

def transform(msg):
    return {
        'op': 'find-symbol',
        'dir': current_path(self.nvim),
        'file': current_file(self.nvim),
        'ns': msg['ns'],
        'name': msg['name'],
        'line': msg.get('line', 1),
        'column': msg.get('column', 1),
        'serialization-format': 'bencode'
    }

class Handler(WithFSM):

    name = 'Usage'

    def handle_init(self, msg, *_):
        new_data = transform(msg)
        self.change_state('usage', new_data)

    def handle_usage(self, *_):
        pass
