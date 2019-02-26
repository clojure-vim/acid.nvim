![acid.nvim](https://raw.githubusercontent.com/clojure-vim/acid.nvim/master/acidnvim.png)

Asynchronous Clojure Interactive Development

## What is it for?

Acid.nvim is a plugin for clojure development on neovim.
It was initially designed within [iron.nvim](http://github.com/clojure-vim/iron.nvim), but evolved to be a proper clojure plugin for neovim.

## Design and Structure

Acid provides a range of tools to deal with nREPL connectivity, messaging and source code interaction.

## Installing

First, install the python dependencies:

```bash
pip3 install --user neovim
```

Then, add and install acid:

```vim
Plug 'clojure-vim/acid.nvim', { 'do': ':UpdateRemotePlugins' }
```

Acid is a remote plugin. This means it communicates with neovim using the rpc interface.

Most of acids functionality are available through the lua interface.
As lua doesn't provide the required asynchronous capabilities for handling
nREPL connectivity, a python layer exists to provide them.

Nonetheless, one should never require to interact with python directly.

## Functionality

Acid provides multiple 
