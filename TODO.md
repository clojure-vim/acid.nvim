# 0.1 Navigation
Deoplete completion will be maintained on
[async-clj-omni](https://github.com/clojure-vim/async-clj-omni/)

- [x] Make async **for real**
 - [x] Use WatchableConnection
- [x] Automatic Require
 - [x] Autocommand
- [x] Implement Go To Symbol v1
 - [x] Same Project

# 0.2 API Stabilization

- [x] Stable API
- [x] Implement commands as extensible structures
- [x] Implement handlers as extensible structures
- [x] Add logging to session handler
- [x] Add logging to messages handler
  - [x] Add an opt-in variable for logging -> `acid_log_messages`

# 0.3 Structure Hardening

- [x] Allow non-python callbacks
- [x] Outsource window/screen management
- [x] Provide means to deal with jars
- [x] Provide means to build new tools with it

# 1.0 Simple

- [x] Simplify structures, bindings and connectivity


# 1.1 Stabilization of new features

- [ ] Logs
  - [ ] Unify logs for all files
  - [ ] Make logs available for all handlers and commands
- [ ] Messages
  - [ ] Single entry for Logs and `echom` messages
  - [ ] Prepend `Acid: ` on all messages
  - [ ] Expose as a function for all handlers and commands

# 1.2 New features

- [ ] Fire autocommands when first connecting nrepl
- [ ] Inject code when first connecting to a nrepl
