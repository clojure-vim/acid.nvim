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

# 0.3 Refactoring

## Will implement

- [ ] Docs
- [ ] Clojurescript support
- [ ] Implement Go To Symbol v2
 - [ ] Different project with local source
  - [ ] Warn about different version
 - [ ] Different project with no source (open jar)
- [ ] Add missing require/import

## Can possibly be outsourced

- [ ] Convert chained fns to threads
- [ ] Convert threads back to fns
- [ ] Extract variables
  - [ ] To `let`
  - [ ] To `def`
- [ ] Extract functions
  - [ ] To `defn`
  - [ ] To `fn`
  - [ ] To `#()`
- [ ] Change data type
  - [ ] To `vec`
  - [ ] To `list`
  - [ ] To `map`
  - [ ] To `set`

# 0.4 Static

- [ ] Add lein static analysis
  - [ ] [kibit](https://github.com/jonase/kibit)
  - [ ] [bikeshed](https://github.com/dakrone/lein-bikeshed)
  - [ ] [eastwood](https://github.com/jonase/eastwood)
- [ ] Neomake integration

# 1.0 
