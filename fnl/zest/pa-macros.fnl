(fn pa- [repo ...]
  ; NOTE: this doen't suppor nesting
  (let [formatted [(tostring repo)]
        args [...]]
    (each [i v (ipairs args)]
      (when (and (not= 1 i) (= 0 (% (# args) i)))
        (tset formatted (. args (- i 1)) v)))
    `(use ,formatted)))

{: pa-}
