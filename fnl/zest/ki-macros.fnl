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

(local state {:id 0})

(fn new-id []
  (let [id (. state :id)]
    (tset state :id (+ 1 id))
    id))

(fn ki- [options fs ts]
  (let [modes (x-str (table.remove options 1))
        f (x-str fs)
        callback? (is-callback? ts)
        id (.. "_____ki" (new-id))
        o (parse-opt (xs-str options))
        t (if callback?
            (if (. o :expr)
              (.. "v:lua." id "()")
              (.. ":lua _G." id "()<cr>"))
            (x-str ts))
        r []]
    (when callback?
      (table.insert r `(tset _G ,id #,ts)))
    (each [m (string.gmatch modes ".")]
      (table.insert r `(vim.api.nvim_set_keymap ,m ,f ,t ,o)))
    r))


{: ki-
 : is-callback?
 : my-def}
