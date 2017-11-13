# Untargeted

- [ ] Support for sessions
- [ ] Editing files inside the nrepl
- [ ] Editing files outside the nrepl:
  - [ ] Using the clojure parser
  - [ ] Pasting data from the nrepl
- [ ] Support `.cljc` files (default to `clojure` while no support for `clojurescript`)
- [ ] Support `.cljs` files (thus, support `clojurescript`)

# 1.2 Docs and declarative stuff

- [ ] High level documentation on acid acrchitecture
- [ ] Add docs for commands
- [ ] Show docs for commands
- [ ] Show current maps
- [ ] Show current configs for commands
- [ ] Make commands available as early as possible

# 1.1

- [x] Fire autocommands when first connecting nrepl
- [x] New File (creates with namespace already)
- [x] Rename file (renames imports as well)
- [x] Ignore 'comment' blocks when evaluating code

# 1.0 Simple

- [x] Simplify structures, bindings and connectivity
- [x] Logs
- [x] Messages

# 0.3 Structure Hardening

- [x] Allow non-python callbacks
- [x] Outsource window/screen management
- [x] Provide means to deal with jars
- [x] Provide means to build new tools with it

# 0.2 API Stabilization

- [x] Stable API
- [x] Implement commands as extensible structures
- [x] Implement handlers as extensible structures
- [x] Add logging to session handler
- [x] Add logging to messages handler
  - [x] Add an opt-in variable for logging -> `acid_log_messages`

# 0.1 Navigation
Deoplete completion will be maintained on
[async-clj-omni](https://github.com/clojure-vim/async-clj-omni/)

- [x] Make async **for real**
 - [x] Use WatchableConnection
- [x] Automatic Require
 - [x] Autocommand
- [x] Implement Go To Symbol v1
 - [x] Same Project
