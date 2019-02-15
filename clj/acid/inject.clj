(ns acid.inject
  (:require [clojure.pprint :as p]))

(defn manipulate-req [reqs modify]
  (let [[[h] v] (split-at 1 reqs)]
    (conj (sort-by first (modify v)) h)))

(defn sort-reqs [reqs]
  (manipulate-req reqs identity))

(defn add-req [new-req reqs]
  (manipulate-req reqs #(conj % new-req)))

(defn rem-req [old-req reqs]
  (manipulate-req reqs (partial remove #(= old-req (first %)))))

(defn map-if [pred action col]
  (apply list (map (fn [v]
                     (if (pred v)
                       (action v)
                       v))
                   col)))

(defn format-code [code]
  (p/with-pprint-dispatch
    p/code-dispatch
    (p/pprint
      (clojure.edn/read-string (str code)))))

(defn upd-ns [decl symb action]
  (map-if #(when (seq? %) (#{symb} (first %))) action decl))
