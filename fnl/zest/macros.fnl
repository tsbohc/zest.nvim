; internal

; I should bind vim.api.nvim_set_keymap locally when using it multiple times
; hmmm, need to bench that

(local M {})

(fn _encode [s]
  "convert characters of string 's' to byte_"
  (if (= (type s) :string)
    `,(.. "_" (string.gsub s "." (fn [ZEST_C#] (.. (string.byte ZEST_C#) "_"))))
    `(.. "_" (string.gsub ,s "." (fn [ZEST_C#] (.. (string.byte ZEST_C#) "_"))))))

(fn M.smart-concat [xs d]
  "concatenate only literal strings in seq 'xs'"
  (let [d (or d "")
        out []
        f (require :zest.fennel)]
    (if (= (type xs) :string)
      ; simply pass literal strings through
      (table.insert out xs)
      (if (f.sym? xs)
        ; decide what to do with variables at runtime
        (table.insert out
          `(if (= (type ,xs) :string)
             ,xs
             (table.concat ,xs ,d)))
        ; do whatever we can at compile time
        (do
          (var last-string? false)
          (each [_ v (ipairs xs)]
            (let [string? (= (type v) :string)
                  len (length out)]
              (if (and last-string?
                       string?)
                (tset out len (.. (. out len) d v))
                (table.insert out v))
              (set last-string? string?))))))
    (if (= (length out) 1)
      (unpack out)
      (if (= d "")
        `(.. ,(unpack out))
        `(table.concat ,out ,d)))))

(fn _vlua [f kind id]
  "store function 'f' into _G._zest and return its v:lua"
  (if id
    `(let [ZEST_ID# ,(_encode id)]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))
    `(let [ZEST_N# (. _G._zest ,kind :#)
           ZEST_ID# (.. "_" ZEST_N#)]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (tset _G._zest ,kind :# (+ ZEST_N# 1))
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))))

; notes: we can't do book keeping at compile time as ids will get overridden unless they're all compiled at once
; hmmm what if we compile aaaaall files at once into a single init.lua?

(fn _vlua-format [s f kind id]
  "a string.format wrapper for _vlua"
  `(string.format ,s ,(_vlua f kind id)))

; vlua

(fn M.vlua [f]
  "a user macro for _vlua"
  `,(_vlua f :v))

(fn M.vlua-format [s f]
  "a user macro for _vlua-format"
  `,(_vlua-format s f :v))

; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts-xs args
        opts {:noremap true}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn M.def-keymap [...]
  (let [arg-xs [...]
        out []]
    (match (# arg-xs)
      3 (let [(fs args ts) (unpack arg-xs)
              (modes opts) (_keymap-options args)]
          (if (> (length modes) 1)
            (do
              (each [m (string.gmatch modes ".")]
                (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ZEST_OPTS#)))
              `(let [ZEST_OPTS# ,opts]
                 ,(unpack out)))
            `(vim.api.nvim_set_keymap ,modes ,fs ,ts ,opts)))
      2 (let [(args xt) (unpack arg-xs)
              (modes opts) (_keymap-options args)]
          (each [fs ts (pairs xt)]
            (each [m (string.gmatch modes ".")]
              (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ZEST_OPTS#))))
          `(let [ZEST_OPTS# ,opts]
             ,(unpack out))))))

(fn M.def-keymap-fn [fs args ...]
  (let [(modes opts) (_keymap-options args)
        vlua (_vlua `(fn [] ,...) :keymap (M.smart-concat [fs modes]))
        rhs (if opts.expr
              `(.. ZEST_VLUA# "()")
              `(.. ":call " ZEST_VLUA# "()<cr>"))
        out []]
    (if (> (length modes) 1)
      (do
        (each [m (string.gmatch modes ".")]
          (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ZEST_RHS# ZEST_OPTS#)))
        `(let [ZEST_VLUA# ,vlua
               ZEST_RHS# ,rhs
               ZEST_OPTS# ,opts]
           ,(unpack out)))
      `(let [ZEST_VLUA# ,vlua
             ZEST_RHS# ,rhs]
         (vim.api.nvim_set_keymap ,modes ,fs ZEST_RHS# ,opts)))))

; autocmd

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [out []
        body (if ...  `[(do ,...)] `[])
        opening (M.smart-concat ["augroup" name] " ")]
    `(do
       (vim.cmd ,opening)
       ,(when (not dirty?)
          `(vim.cmd "autocmd!"))
       ,(unpack body)
       (vim.cmd "augroup END"))))

(fn M.def-augroup [name ...]
  (_create-augroup false name ...))

(fn M.def-augroup-dirty [name ...]
  (_create-augroup true name ...))

(fn M.def-autocmd [events patterns ts]
  (let [events (M.smart-concat events ",")
        patterns (M.smart-concat patterns ",")
        command (M.smart-concat ["au " events " " patterns " " ts])]
    `(vim.cmd ,command)))

(fn M.def-autocmd-fn [events patterns ...]
  (let [events (M.smart-concat events ",")
        patterns (M.smart-concat patterns ",")
        vlua (_vlua `(fn [] ,...) :autocmd)
        command (M.smart-concat ["autocmd " events " " patterns " :call " `ZEST_VLUA# "()"])]
    `(let [ZEST_VLUA# ,vlua]
       (vim.cmd ,command))))

; command

(fn _dumb-varg? [xs]
  (var va? false)
  (for [i 1 (length xs)]
    (when (= (tostring (. xs i)) "...")
      (set va? true)))
  va?)

(fn M.def-command-fn [name args ...]
  (let [len (length args)
        vlua (_vlua `(fn ,args ,...) :command name)
        va? (_dumb-varg? args)
        nargs (.. "-nargs=" (if va?  "*" (match len 0 "0" 1 "1" _ "*")))
        f-args (if va?  "<f-args>" (match len 0 "" 1 "<q-args>" _ "<f-args>"))
        command (M.smart-concat ["command " nargs " " name " :call " `ZEST_VLUA# "(" f-args ")"])]
    `(let [ZEST_VLUA# ,vlua]
       (vim.cmd ,command))))

; setoption bakery

; opt-set      opt-local-set      opt-global-set
; opt-get      opt-local-get      opt-global-get
; opt-append   opt-local-append   opt-global-append
; opt-prepend  opt-local-prepend  opt-global-prepend
; opt-remove   opt-local-remove   opt-global-remove

(fn _opt-set [scope key val]
  (let [key (tostring key)
        val (if (= nil val) true val)]
    `(tset (. vim ,(.. :opt scope)) ,key ,val)))

(fn _opt-act [scope key val act]
  (let [key (tostring key)
        opt `(. vim ,(.. :opt scope) ,key)]
    `(: ,opt ,act ,val)))

(each [_ scope (ipairs ["" "_local" "_global"])]
  (tset M (.. "opt" (scope:gsub "_" "-") "-set")
        (fn [key val]
          (_opt-set scope key val))))

(each [_ scope (ipairs ["" "_local" "_global"])]
  (each [_ act (ipairs [:get :append :prepend :remove])]
    (tset M (.. "opt" (scope:gsub "_" "-") "-" act)
          (fn [key val]
            (_opt-act scope key val act)))))

; packer

(fn M.packer-use-wrapper [repo opts]
  (let [xt [repo]]
    (when opts
      ; FIXME needs to be a deep copy
      (each [k v (pairs opts)]
        (tset xt k v)))
    `(use ,xt)))

; let

(fn M.let-g [k v]
  "set 'k' to 'v' on vim.g table"
  `(tset vim.g ,(tostring k) ,v))

; highlight?

M
