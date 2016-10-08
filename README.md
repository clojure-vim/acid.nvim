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

## Running

Acid requires you to have a running REPL on the current directory.

If you want to have asynchronous autocompletion with [deoplete](https://github.com/shougo/deoplete), add this snippet to your init.vim:

```vim
let g:deoplete#sources = {}
let g:deoplete#sources._ = ['buffer', 'file']

" Adds acid as a source to deoplete
let g:deoplete#sources.clojure = ['acid']
```

Also, acid is capable of navigation to symbol definition:

```vim
"with a function
:call AcidGoTo("some-symbol")

"with a command, getting the symbol under the cursor
:AcidGoToDefinition

"or with a mapping
<C-D> "Same as <C-S-d>
```

## Cool, I want more

Acid is still very young and does not have much functionality implemented yet. Please take a look at the [TODO](https://github.com/hkupty/acid.nvim/blob/master/TODO.md) for the roadmap.
