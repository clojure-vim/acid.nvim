# acid.connections
low-level connection handler

## `acid.connections.add(addr)`
Stores connection for reuse later

addr **({string,string})**: Address tuple with ip and port.


## `acid.connections.select(pwd, ix)`
Elects selected connection as primary (thus default) for a certain address

pwd **(string)**: path (usually project root).
 Assumed to be neovim's `pwd`.

ix **(int)**: index of the stored connection


## `acid.connections.unselect(pwd)`
Dissociates the connection for the given path

pwd **(string)**: path (usually project root).


## `acid.connections.get(pwd)`
Return active connection for the given path

pwd **(string)**: path (usually project root).


**({string,string})** Connection tuple with ip and port or nil.


## `acid.connections.set(pwd, Connection)`
Add and select the given connection for given path.

pwd **(string)**: path (usually project root).

Connection **({string,string})**: tuple with ip and port or nil.


---

# acid.core
low-level connection handler.

## `acid.core.send([conn], obj, handler)`
Forward messages to the nrepl and registers the handler.

*conn* **({string,string})**: Ip and Port tuple. Will try to get one if nil.

obj **(table)**: Payload to be sent to the nrepl.

handler **(function)**: Handler function to deal with the response.


---

# acid.features
User-facing features and runnable commands

## `acid.features.eval_cmdline(code[, ns])`
Evaluate the given code and insert the result at the cursor position

code **(string)**: Clojure s-expression to be evaluated on the nrepl

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.


## `acid.features.eval_print(code[, ns])`
Evaluate the given code and print the result.

code **(string)**: Clojure s-expression to be evaluated on the nrepl

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.


## `acid.features.eval_expr([mode[, ns]])`
Evaluate the current form or the given motion.

*mode* **(string)**: motion mode

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.


## `acid.features.do_require([ns[, ...]])`
Sends a `(require '[...])` function to the nrepl.

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.

*...*: extra arguments to the require function


## `acid.features.do_import(java_ns, symbols)`
Sends a `(import '[...])` function to the nrepl.

java_ns **(string)**: Namespace of the java symbols that are being imported.

symbols **({string,...})**: List of java symbols to be imported


## `acid.features.go_to([symbol[, ns]])`
Navigates the the definition of the given symbol.

*symbol* **(string)**: Symbol to navigate to. Defaults to symbol under
 cursor.

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.


## `acid.features.docs([symbol[, ns]])`
Shows the docstring of the given symbol.

*symbol* **(string)**: Symbol which docs will be shown. Defaults to symbol under cursor.

*ns* **(string)**: Namespace to be used when evaluating the code.
 Defaults to current file's ns.


## `acid.features.preload()`
Inject some clojure files into the nrepl sesion.


## `acid.features.load_all_nss()`
Load all namespaces in the current session.


## `acid.features.add_require(req)`
Refactor the current file to include the given argument in the
`(:requires ...)` section.

req **(string)**: require vector, such as `[clojure.string :as str]`.


## `acid.features.remove_require(req)`
Refactor the current file to remove the given argument from the
`(:requires ...)` section.

req **(string)**: require namespace, such as `clojure.string`.


## `acid.features.sort_requires()`
Refactor the current file so the `(:require ...)` form is sorted.


---

# acid.forms
Forms extraction

## `acid.forms.get_form_boundaries()`
Returns the coordinates for the boundaries of the current form


**(table)** coordinates {from = {row,col}, to = {row,col}}


## `acid.forms.form_from_motion(mode[, bufnr])`
Extracts the form according to given motion (or visual mode)

mode **(string)**: Motion mode or 'visual'

*bufnr* **(int)**: Buffer number in neovim. Will take current if none given


**(string)** symbol under cursor

**(table)** coordinates {from = {row,col}, to = {row,col}, bufnr = 1}


## `acid.forms.form_under_cursor()`
Extracts the innermost form under the cursor


**(string)** symbol under cursor

**(table)** coordinates {from = {row,col}, to = {row,col}, bufnr = 1}


## `acid.forms.symbol_under_cursor()`
Extracts the symbol under the cursor


**(string)** symbol under cursor

**(table)** coordinates {from = {row,col}, to = {row,col}, bofnr = 1}


---

# acid
Frontend module with most relevant functions

## `acid.connected([pwd])`
Checks whether a connection exists for supplied path or not.

*pwd* **(string)**: Path bound to connection.
 Will call `getcwd` on neovim if not supplied


**(boolean)** Whether a connection exists or not.


## `acid.run(cmd, conn)`
Façade to core.send

cmd: A command (op + payload + handler) to be executed.

conn: A connection where this command will be run.


## `acid.callback(session, ret)`
Callback proxy for handling command responses

session: Session ID for matching response with request

ret: The response from nrepl


---

# acid.nrepl
nRepl connectivity

## `middlewares`
List of supported middlewares and the wrappers to invoke when spawning a nrepl process.

Values:

* `[nrepl/nrepl]`

## `default_middlewares`
Default middlewares that will be used by the nrepl server

Values:

* `nrepl/nrepl`
* `cider/cider-nrepl`
* `refactor-nrepl`

## `acid.nrepl.start(obj)`
Starts a tools.deps nrepl server

obj **(table)**: Configuration for the nrepl process to be spawn

Parameters for table `obj` are:

* *obj.pwd* **(string)**: Path where the nrepl process will be started
* *obj.middlewares* **(table)**: List of middlewares.
* *obj.alias* **(string)**: alias on the local deps.edn
* *obj.connect* **(string)**: -c parameter for the nrepl process
* *obj.bind* **(string)**: -b parameter for the nrepl process

**(boolean)** Whether it was possible to spawn a nrepl process


## `acid.nrepl.stop(obj)`
Stops a nrepl process managed by acid

obj **(table)**: Configuration for the nrepl process to be stopped

Parameters for table `obj` are:

* obj.pwd **(string)**: Path where the nrepl process was started

## `acid.nrepl.show([ch])`
Debugs nrepl connection by returning the captured output

*ch* **(int)**: Neovim's job id of given nrepl process. When not supplied return all.


**(table)** table with the captured outputs for given (or all) nrepl process(es).

