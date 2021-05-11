(fn xs-str [xs]
  "convert seq 'xs' to a seq of stringified entries"
  (when (not= nil xs)
    (let [r []]
      (for [i 1 (# xs)]
        (table.insert r `,(tostring (. xs i))))
      r)))

(fn x-str [x]
  "convert symbol 'xs' to a string"
  `,(tostring x))

(fn parse-opt [options]
  "convert internal option seq to nvim option dict"
  (let [parsed {:noremap true}]
    (when (not= nil options)
      (each [_ o (ipairs options)]
        (if (= o :remap)
          (tset parsed :noremap false)
          (tset parsed o true))))
    parsed))

; output a call to require c.fnl on first usage?
(fn ki- [args fs ts]
  "bind 'fs' to 'ts' with 'args' via runtime evaluation"
  (let [modes (x-str (table.remove args 1))
        opts (parse-opt (xs-str args))]
    `((require :zest.bind) ,modes ,fs ,ts ,opts)))

(fn li- [options fs ts]
  "bind 'fs' to 'ts' literals at compile time"
  (let [modes (x-str (table.remove options 1))
        o (parse-opt (xs-str options))
        f (x-str fs)
        t (x-str ts)
        r []]
    (each [m (string.gmatch modes ".")]
      (table.insert r `(vim.api.nvim_set_keymap ,m ,f ,t ,o)))
    r))

{: ki-
 : li-}
