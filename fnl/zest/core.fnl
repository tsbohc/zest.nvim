(local core {})

(fn core.seq? [xs]
  "check if table is a sequence"
  (var i 0)
  (each [_ (pairs xs)]
    (set i (+ i 1))
    (if (= nil (. xs i))
      (lua "return false")))
  true)

(fn core.has? [xt y]
  "check if table contains a value or a (k, v) pair"
  (if (core.seq? xt)
    (each [_ v (ipairs xt)]
      (when (= v y)
        (lua "return true")))
    (when (not= nil (. xt y))
      (lua "return true")))
  false)

core
