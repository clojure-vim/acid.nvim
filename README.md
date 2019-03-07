![acid.nvim](https://raw.githubusercontent.com/clojure-vim/acid.nvim/master/acidnvim.png)

Asynchronous Clojure Interactive Development

## What is it for?

Acid.nvim is a plugin for clojure development on neovim.
Started as the evolution of clojure-specific code that was living in [iron.nvim](https://github.com/clojure-vim/iron.nvim) and grew into a full-fledged [nREPL](https://github.com/nrepl/nrepl) client.

## Design and Structure

Acid provides a range of tools to deal with nREPL connectivity, messaging and source code interaction.

## Installing

First, install the python dependencies:

```bash
pip3 install --user pynvim
```

Then, add and install acid:

```vim
Plug 'clojure-vim/acid.nvim', { 'do': ':UpdateRemotePlugins' }
```

Most of acid functionality is available through the lua interface.
As lua doesn't provide the required asynchronous capabilities for handling
nREPL connectivity, a python layer exists to provide them.

Nonetheless, one should never require to interact with python directly.
