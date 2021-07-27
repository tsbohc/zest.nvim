; internal

(fn _encode [s]
  "convert characters of string 's' to byte_"
  (if (= (type s) :string)
    `,(.. "_" (string.gsub s "."
                (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))
    `(.. "_" (string.gsub ,s "."
               (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))))

(fn _smart-concat [xs d]
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
        ; do whatever we can with literal sequences
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

;(fn _vlua [f kind id]
;  "store function 'f' into _G._zest and return its v:lua"
;  (if id
;    `(let [ZEST_ID# ,(_encode id)]
;       (tset _G._zest ,kind ZEST_ID# ,f)
;       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))
;    `(let [ZEST_N# (. _G._zest ,kind :#)
;           ZEST_ID# (.. "_" ZEST_N#)]
;       (tset _G._zest ,kind ZEST_ID# ,f)
;       (tset _G._zest ,kind :# (+ ZEST_N# 1))
;       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))))

(fn _vlua-format [s f kind id]
  "a string.format wrapper for _vlua"
  `(string.format ,s ,(_vlua f kind id)))

(local M {})

(fn M.concat [xs d]
  (_smart-concat xs d))

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
        v (_vlua `(fn [] ,...) :keymap (_smart-concat [fs modes]))
        rhs (if opts.expr
              `(.. ZEST_VLUA# "()")
              `(.. ":call " ZEST_VLUA# "()<cr>"))
        out []]
    (if (> (length modes) 1)
      (do
        (each [m (string.gmatch modes ".")]
          (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ZEST_RHS# ZEST_OPTS#)))
        `(let [ZEST_VLUA# ,v
               ZEST_RHS# ,rhs
               ZEST_OPTS# ,opts]
           ,(unpack out)))
      `(let [ZEST_VLUA# ,v
             ZEST_RHS# ,rhs]
         (vim.api.nvim_set_keymap ,modes ,fs ZEST_RHS# ,opts)))))

; autocmd

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [out []
        body (if ...  `[(do ,...)] `[])
        opening (_smart-concat ["augroup" name] " ")]
    `(do
       (vim.api.nvim_command ,opening)
       ,(when (not dirty?)
          `(vim.api.nvim_command "autocmd!"))
       ,(unpack body)
       (vim.api.nvim_command "augroup END"))))

(fn M.def-augroup [name ...]
  (_create-augroup false name ...))

(fn M.def-augroup-dirty [name ...]
  (_create-augroup true name ...))

(fn M.def-autocmd [events patterns ts]
  (let [events (_smart-concat events ",")
        patterns (_smart-concat patterns ",")
        command (_smart-concat ["au " events " " patterns " " ts])]
    `(vim.api.nvim_command ,command)))

(fn M.def-autocmd-fn [events patterns ...]
  (let [events (_smart-concat events ",")
        patterns (_smart-concat patterns ",")
        v (_vlua `(fn [] ,...) :autocmd)
        command (_smart-concat ["autocmd " events " " patterns " :call " `ZEST_VLUA# "()"])]
    `(let [ZEST_VLUA# ,v]
       (vim.api.nvim_command ,command))))

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

; TODO

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
