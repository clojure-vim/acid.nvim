(ns acid.refactor.manage-requires)

(defn manipulate-req [reqs modify]
  (let [[[h] v] (split-at 1 reqs)]
    (conj (sort-by first (modify v)) h)))

(defn sort-reqs [reqs]
  (manipulate-req reqs identity))

(defn add-req [reqs new-req]
  (manipulate-req reqs #(conj % new-req)))

(defn rem-req [reqs new-req]
  (manipulate-req reqs (partial remove #(= new-req (first %)))))
