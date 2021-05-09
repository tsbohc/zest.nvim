(fn xs-str [xs]
  (when (not= nil xs)
    (let [r []]
      (for [i 1 (# xs)]
        (table.insert r `,(tostring (. xs i))))
      r)))

(fn x-str [x]
  `,(tostring x))

(fn is-callback? [x]
  ; now this is stupid but effective
  (let [s `,(tostring x)]
    (when (= "(" (s:sub 1 1))
      true)))

(fn my-def [...]
  `(tset _G :wooo #,...))

(fn parse-opt [op]
  (let [parsed {:noremap true}]
    (when (not= nil op)
      (each [_ o (ipairs op)]
        (if (= o :remap)
          (tset parsed :noremap false)
          (tset parsed o true))))
    parsed))

(fn ki- [opts fs ts]
  ; we gotta be careful with ts
  (let [ms (x-str (table.remove opts 1))
        fs (x-str fs)
        callback? (is-callback? ts)
        t (if callback?
             (.. "v:lua." :wooo "()")
             (x-str ts))
        op (parse-opt (xs-str opts))]
    `(do
       ,(when callback? (my-def ts))
       (each [m# (string.gmatch ,ms ".")]
         (vim.api.nvim_set_keymap m# ,fs ,t ,op)))))

{: ki-
 : is-callback?
 : my-def}
