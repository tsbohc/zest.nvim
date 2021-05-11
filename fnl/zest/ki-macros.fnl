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

(fn parse-opt [options]
  (let [parsed {:noremap true}]
    (when (not= nil options)
      (each [_ o (ipairs options)]
        (if (= o :remap)
          (tset parsed :noremap false)
          (tset parsed o true))))
    parsed))

(local state {:id 0})

(fn new-id []
  (let [id (. state :id)]
    (tset state :id (+ 1 id))
    id))

; FIXME: breaks on numbers
(fn get-type [x]
  (let [e (tostring (. x 1))
        s `,(tostring x)]
    (if (or (= (s:sub 1 1) "#") (= (s:sub 1 1) "("))
      (if (or (= e "fn") (= e "hashfn"))
        "function"
        "expression")
      "literal")))

(fn proc-fs [fs]
  (let [t (get-type fs)]
    (match t
      :expression fs
      :literal (x-str fs))))

(fn proc-ts [ts]
  ; need options here
  ; also need to put the _G pass to retult value, can't return both
  (let [t (get-type ts)]
    (match t
      :expression ts
      :literal (x-str ts)
      :function (let [id (new-id)]
                  `(tset _G ,id ,ts)))))

(fn b [options fs ts]
  (let [modes (x-str (table.remove options 1))
        o (parse-opt (xs-str options))
        fs-type (get-type fs)
        ts-type (get-type ts)
        out []
        f (let [t (get-type fs)]
            (match t
              :expression fs
              :literal (x-str fs)
              :function (fs)))
        t (let [t (get-type ts)]
            (match t
              :expression ts
              :literal (x-str ts)
              :function (let [id (.. "_____ki" (new-id))]
                          (table.insert out `(tset _G ,id ,ts))
                          (if (. o :expr)
                            (.. "v:lua." id "()")
                            (.. ":lua _G." id "()<cr>")))))
        ]
    out
    ))

;(fn ki- [options fs ts]
;  (let [modes (x-str (table.remove options 1))
;        f (x-str fs)
;        callback? (is-callback? ts)
;        id (.. "_____ki" (new-id))
;        o (parse-opt (xs-str options))
;        t (if callback?
;            (if (. o :expr)
;              (.. "v:lua." id "()")
;              (.. ":lua _G." id "()<cr>"))
;            (x-str ts))
;        r []]
;    (when callback?
;      (table.insert r `(tset _G ,id #,ts)))
;    (each [m (string.gmatch modes ".")]
;      (table.insert r `(vim.api.nvim_set_keymap ,m ,f ,t ,o)))
;    r))


;(local bind {})
;
;(fn bind.literal [modes fs ts o]
;  (let [r []
;        f ]
;    (each [m (string.gmatch modes ".")]
;      (table.insert r `(vim.api.nvim_set_keymap ,m ,f ,t ,o)))
;    r))
;
;(fn bind [options fs ts]
;  (let [t (get-type ts)
;        o (parse-opt (xs-str options))]
;    (match t
;      :function (bind.function modes fs ts o)
;      :expression (bind.expression modes fs ts o)
;      :literal (bind.expression modes fs ts o))))

; non-literal
(fn ki- [options fs ts]
  (let [modes (x-str (table.remove options 1))
        o (parse-opt (xs-str options))
        id (.. "_____ki" (new-id))
        t (if (. o :expr)
            (.. "v:lua." id "()")
            (.. ":lua _G." id "()<cr>"))
        r []]
    (table.insert r `(tset _G ,id ,ts))
    r))

; literal
(fn li- [options fs ts]
  (let [modes (x-str (table.remove options 1))
        o (parse-opt (xs-str options))
        f (x-str fs)
        t (x-str ts)
        r []]
    (each [m (string.gmatch modes ".")]
      (table.insert r `(vim.api.nvim_set_keymap ,m ,f ,t ,o)))
    r))

; smart??

{: ki-
 : li-
 : get-type
 : is-callback?
 : proc-fs
 : proc-ts
 : b}
