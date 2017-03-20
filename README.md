(https://github.com/clojure-vim/acid.nvim/raw/acidnvim.png "acid.nvim")

Asynchronous Clojure Interactive Development

## What is it for?

Acid.nvim is a plugin for clojure development on neovim.
It was initially designed within [iron.nvim](http://github.com/clojure-vim/iron.nvim), but evolved to be a proper clojure plugin for neovim.

## Design and Structure

It is built fundamentally on neovims async capabilities and rely deeply on clojures
[refactor-nrepl](https://github.com/clojure-emacs/refactor-nrepl) and
[nrepl-python-client](https://github.com/cemerick/nrepl-python-client).

## Installing

First, install the python dependencies:

```bash
pip3 install --user neovim
```

Then, add and install acid:

```vim
Plug 'clojure-vim/acid.nvim'
```

Update your `~/.lein/profiles.clj` adding the following lines:
```clj
[refactor-nrepl "2.3.0-SNAPSHOT"]
[cider/cider-nrepl "0.14.0"]
```

## Running

Acid requires you to have a running REPL on the current directory.

Some of the features are outlined below:

```vim
" Evaluating code

" Send output of a command to a neovim buffer
:call AcidEval({'op': 'eval', 'code': '(some-fn "")'})

" Symbol Navigation

" With a function
:call AcidGoTo("some-symbol")

" With a command, getting the symbol under the cursor
:AcidGoToDefinition

" Or with a mapping

" Requiring current file
" With a command
:AcidRequire

" Automatically, for all files
:let g:acid_auto_require=1
<C-F>
```

## Cool, I want more

Acid is still very young and does not have much functionality implemented yet. Please take a look at the [TODO](https://github.com/clojure-vim/acid.nvim/blob/master/TODO.md) for the roadmap.
