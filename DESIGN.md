# Current

Acid current design is simple and can be divided into two main parts:

* Acid Core
  * Commands
  * Handlers
* Session Handler

The roundtrip can be described as follows:

```
nvim    AcidCore    Command    SessionHandler    nrepl    Handler
  1---------|
            2----------|
            |----------3
            4-------------------------|
                                      5------------|
                                      |------------6
                                      7----------------------|
  |----------------------------------------------------------8
```

  1. A Message is sent to acid through the `AcidCommand` command;
  2. Acid locates the command and requests a payload to send to the nrepl;
  3. The command returns a nrepl message (i.e. `{'op': 'eval', 'code': '(+ 1 1)'}`);
  4. The core then sends the message to the session handler;
  5. The session handler finds or creates a connection to the repl and sends the message;
  6. The message is processed by the nrepl, wich responds;
  7. The session handler captures the response and directs it to the appropriate handler;
  8. The handler interprets the response and update neovim accordingly.

## Acid Core

Acid core is where the neovim interface is defined. Whenever you want to add a neovim `command! AcidStuff`, you should look here.

### Commands

All commands are defined as python3 classes and their behavior configured by metadata.
They are 'lazily' loaded when acid starts. This means that you can add your own commands.
All you have to do is add it to the `runtimepath`, so it matches the `$VIMRUNTIME/*/rplugin/python3/acid/command/`


For instance, take the current definition of the `AcidDoc` command:

```python
    name = 'Doc'
    nargs = 1
    handlers = ['Doc']
    op = "info"
    shorthand_mapping = 'K'
    shorthand = 'call setreg("s", expand("<cword>"))'
```

This snippet defines several things about the command:

* Its name is `Doc`, which is prepended with `Acid`, thus having a 'unique/namespaced' command name;
* It takes a single argument;
* There is a single handler that takes it output, also called `Doc`;
* The `op` it requires on nrepl is `info`;
* The 'shorthand' mapping it defines is `K`;
* `shorthand` makes the call self-contained, using the expression to define which is the argument.

### Handlers

Handlers are on the other end of the communication, receiving nrepl messages and somehow interacting with neovim.

The meta-repl is a good example. It formats messages into a throwaway buffer that can be cleared, reused and discarded at will.

# Future

There are some ideas to make acid even better:

## Make `commands` reusable

Allow a command to be remapped with other `handler`/`effect` at will, preserving the first.
This way we can have two `eval` definitions, one yielding to a `meta-repl` and the other saving the result to a register.


## Rework `command` -> `handler` interaction

Split handlers into "transformations" and `effect`s
Transformations are defined inside the command, with a DSL.
`effect`s are lower level interactions with neovim:

  * Echo;
  * Refactor;
  * Call function;
  * Go to;

## Other interesting stuff:

* Create docs from `command`/`handler`/`effect` metadata;
* Make commands handle `autocommands`;
* Issue more `autocommands`, making it async by side-effect of `autocmds`.
