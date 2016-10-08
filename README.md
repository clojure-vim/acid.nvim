# acid.nvim

Asynchronous Clojure Interactive Development

## What is it for?

Acid.nvim is a plugin for clojure development on neovim.
It was initially designed within [iron.nvim](http://github.com/hkupty/iron.nvim), but evolved to be a proper clojure plugin for neovim.

## Design and Structure

It is built fundamentally on neovims async capabilities and rely deeply on clojures
[refactor-nrepl](https://github.com/clojure-emacs/refactor-nrepl) and
[nrepl-python-client](https://github.com/cemerick/nrepl-python-client).

## Installing

First, install the python dependencies:

```bash
pip3 install --user neovim nrepl-python-client
```

Then, add and install acid:

```vim
Plug 'hkupty/acid.nvim'
```
