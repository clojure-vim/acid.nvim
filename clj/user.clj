(ns user)

(defn- requiring-resolve [sym]
  (require (symbol (namespace sym)))
  (resolve sym))

(defmacro jit
  "Just in time loading of dependencies."
  [sym]
  `(requiring-resolve '~sym))

(defn get-ns [fname]
  ((jit clojure.tools.namespace.parse/name-from-ns-decls)
   ((jit clojure.tools.namespace.file/read-file-ns-decl) fname)))
