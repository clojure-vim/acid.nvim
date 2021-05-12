(ns acid.inject
  (:require [clojure.pprint :as p]))

(defn manipulate-req [reqs modify]
  (let [[[h] v] (split-at 1 reqs)]
    (conj (sort-by first (modify v)) h)))

(defn format-code [code]
  (p/with-pprint-dispatch
    p/code-dispatch
    (p/pprint
      (clojure.edn/read-string code))))

(defn update-ns-decl [ns-decl decl fn-]
  (let [seq-ns-decl (sequence (comp
                                (map-indexed list)
                                (filter (comp coll? second)))
                              ns-decl)]
    (if-let [ix (first (filter (comp
                            #{decl}
                            first
                            second)
                      seq-ns-decl))]
      (sequence (update (vec ns-decl) (first ix) fn-))
      (if-let [[ix _] (first seq-ns-decl)]
        (let [[before after] (split-at ix ns-decl)]
          (concat before (conj after (fn- (list decl)))))
        (concat ns-decl (list (fn- (list decl))))))))

(defn add-req [arg] #(sequence (conj (vec %) (vec arg))))

(defn rem-req [old-req] (partial remove #(= old-req (first %))))
