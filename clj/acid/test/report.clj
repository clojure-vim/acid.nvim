(ns acid.test.report
  (:require [clojure.test :as ct]))

(def ^:dynamic details nil)

(defn- with-error [m k c]
  (if (some? (k c))
    (update c k conj m)
    (assoc c k [m])))

(defmulti acid-clj-test-report :type)

(defmethod acid-clj-test-report :pass [m]
  (ct/inc-report-counter :pass))

(defmethod acid-clj-test-report :fail [m]
  (ct/inc-report-counter :fail)
  (swap! details (partial with-error m :failures)))

(defmethod acid-clj-test-report :error [m]
  (ct/inc-report-counter :error)
  (swap! details (partial with-error m :errors)))

(defmethod acid-clj-test-report :summary [m])

(defmethod acid-clj-test-report :default [m])
(defmethod acid-clj-test-report :begin-test-ns [m])
(defmethod acid-clj-test-report :end-test-ns [m])
(defmethod acid-clj-test-report :begin-test-var [m])
(defmethod acid-clj-test-report :end-test-var [m])


(defn run-n-tests [run-test-fn args]
  (binding [ct/report acid-clj-test-report
            details    (atom {})]
    (-> (apply run-test-fn args)
        (merge @details)
        (dissoc :type))))

(defn run-all-tests [] (run-n-tests ct/run-all-tests []))
(defn run-tests     [& nss] (run-n-tests ct/run-tests nss))
