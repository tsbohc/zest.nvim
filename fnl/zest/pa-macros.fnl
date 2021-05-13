(fn pa- [repo ...]
  (let [formatted [(tostring repo)]
        args [...]
        r []]
    (each [i v (ipairs args)]
      (when (and (not= 1 i) (= 0 (% (# args) i)))
        (let [k (. args (- i 1))]
          (if (not= k :zest)
            (tset formatted k v)
            (table.insert r `(,v))))))
    (table.insert r `(use ,formatted))
    `(do ,(unpack r))))

{: pa-}
