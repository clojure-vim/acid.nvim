![acid.nvim](https://pictshare.net/wvkzwo.png)

# Asynchronous Clojure Interactive Development
## Remote layer (Python)

Below is a schema of the remote codebase layers.

```
  __init__.py --> neovim plugin layer (API)
  nrepl/      --> https://github.com/clojure-vim/nrepl-python-client.git
  nvim/       --> Functions that use neovim infrastructure
  pure/       --> Functions that (should be) independent of neovim
  session.py  --> Frontend for nrepl messagin
```

### API

Those are the functions that the remote layer exposes to neovim.
There are two kinds of functions, though no explicit distinction exists:

* Functions that should be called by the users;
* Functions that should be called by lua code.

#### Ideas

* Maybe use something better than python for this.
  * Golang?
  * Cljs?
  * Probably avoid plugin hosts and omit function handlers alltogether:
    * Use `rpcnotify` and `rpcrequest` directly.
    * In that case, maybe even clojure.
    * Also, that'd allow for a much richer functionality:
      * Could provide better functionality;
      * Could spawn the process quietly;
      * Maybe it'd be easier to support other transports
      * graalvm?

## Lua layer

There are two sets of functionalities:

* Acid core:
  * Nrepl:
    * Spawns nrepls;
    * Delegates connections to connection-management;
  * Sessions:
    * [idea] Should have one per plugin
  * Ops:
    * Basic message formatter (with the given 'op').
  * Connection management:
    * Stores connections;
    * Provides default connection (for a base path)
* Acid features:
  * Features:
    * High level operations with values, handlers and nvim interaction.
  * Commands:
    * Cohesion between ops and data
  * Middlewares (composable handlers):
    * Side-effetcs of applied response from the nrepl
