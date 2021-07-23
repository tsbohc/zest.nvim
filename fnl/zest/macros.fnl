(fn xs-str [xs]
  "convert seq of symbols 'xs' to a seq of strings"
  (let [r []]
    (for [i 1 (# xs)]
      (table.insert r `,(tostring (. xs i))))
    r))

; internal

(fn _encode [s]
  (if (= (type s) :string)
    `,(.. "_" (string.gsub s "."
                (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))
    `(.. "_" (string.gsub ,s "."
               (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))))

(fn _vlua [f kind id]
  (if id
    `(let [ZEST_ID# ,(_encode id)]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))
    `(let [ZEST_ID# (.. "_" (. _G._zest ,kind :#))]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (tset _G._zest ,kind :# (+ (. _G._zest ,kind :#) 1))
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))))

(fn _vlua-format [s f kind id]
  `(string.format ,s ,(_vlua f kind id)))

(local M {})

; vlua

(fn M.vlua [f]
  `,(_vlua f :v))

(fn M.vlua-format [s f]
  `,(_vlua-format s f :v))

; TODO pointless?
(fn M.def-vlua-fn [s ...]
  (let [f `(fn ,...)]
    `,(_vlua-format s f :v)))

; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to modes string and keymap option dict"
  (let [modes (tostring (table.remove args 1))
        opts-xs (xs-str args)
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
          (each [m (string.gmatch modes ".")]
            (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts))))
      2 (let [(args xt) (unpack arg-xs)
              (modes opts) (_keymap-options args)]
          (each [fs ts (pairs xt)]
            (each [m (string.gmatch modes ".")]
              (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts))))))
    `(do ,(unpack out))))

(fn M.def-keymap-fn [fs args ...]
  (let [(modes opts) (_keymap-options args)
        v (_vlua `(fn [] ,...) :keymap fs)]
    `(let [ZEST_VLUA# ,v
           ZEST_RHS# (string.format ,(if opts.expr "%s()" ":call %s()<cr>") ZEST_VLUA#)]
       (each [ZEST_M# (string.gmatch ,modes ".")]
         (vim.api.nvim_set_keymap ZEST_M# ,fs ZEST_RHS# ,opts)))))

; autocmd

(fn _create-augroup [dirty? name ...]
  (let [out []]
    (when (not dirty?)
      (table.insert out `(vim.api.nvim_command "autocmd!")))
    `(do
       (vim.api.nvim_command (.. "augroup " ,name))
       ,(unpack out)
       (do ,...)
       (vim.api.nvim_command (.. "augroup END")))))

(fn M.def-augroup [name ...]
  (_create-augroup false name ...))

(fn M.def-augroup-dirty [name ...]
  (_create-augroup true name ...))

;(fn _create-autocmd [raw? events patterns ts]
;    (if (not raw?)
;      (let [events (table.concat (xs-str events) ",")
;            patterns (if (= (type patterns) :string) patterns (table.concat patterns ","))]
;        `(vim.api.nvim_command (.. "au " ,events " " ,patterns " " ,ts)))
;      `(vim.api.nvim_command (.. "au " (table.concat ,events ",") " " ,patterns " " ,ts))))

(fn _autocmd-options [raw? events patterns]
  (let [events (if (not raw?)
                 (table.concat (xs-str events) ",")
                 events)
        patterns (if (= (type patterns) :string)
                  patterns
                  (if (not raw?)
                    (table.concat (xs-str patterns) ",")
                    patterns))]
    (values events patterns)))

(fn M.def-autocmd [events patterns ts]
  (let [(events patterns) (_autocmd-options false events patterns)]
    `(vim.api.nvim_command (.. "au " ,events " " ,patterns " " ,ts))))

(fn M.def-autocmd-fn [events patterns ...]
  (let [(events patterns) (_autocmd-options false events patterns)
        v (_vlua `(fn [] ,...) :autocmd)]
    `(let [ZEST_VLUA# ,v
           ZEST_RHS# (string.format ":call %s()" ZEST_VLUA#)]
       (vim.api.nvim_command (.. "au " ,events " " ,patterns " " ZEST_RHS#)))))

(fn M.def-autocmd-raw [events patterns ts]
  (let [(events patterns) (_autocmd-options true events patterns)]
    `(vim.api.nvim_command (.. "au " ,events " " ,patterns " " ,ts))))

(fn M.def-autocmd-fn-raw [events patterns ...]
  (let [(events patterns) (_autocmd-options true events patterns)
        v (_vlua `(fn [] ,...) :autocmd)]
    `(let [ZEST_VLUA# ,v
           ZEST_RHS# (string.format ":call %s()" ZEST_VLUA#)]
       (vim.api.nvim_command (.. "au " ,events " " ,patterns " " ZEST_RHS#)))))

; ^ some code duplication, but I think it's more readable this way

; textobject

; TODO prep RHS like this wherever else i can
(fn M.def-textobject [fs ts]
  `(let [ZEST_RHS# (.. ":<c-u>norm! " ,ts "<cr>")]
     (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
     (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true})))

(fn M.def-textobject-fn [fs ...]
  (let [v (_vlua `(fn [] ,...) :textobject fs)]
    `(let [ZEST_VLUA# ,v
           ZEST_RHS# (string.format ":<c-u>call %s()<cr>" ZEST_VLUA#)]
       (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
       (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true}))))

; textoperator

(fn M.def-operator [fs f]
  (let [op `(fn [KIND#]
              (let [REG# (vim.api.nvim_eval "@@")
                    ;KIND# (if (tonumber KIND#) :count KIND#)
                    ]
                (print KIND#) ; => V, ^V
                (match KIND#
                  ;:count (vim.api.nvim_command (.. "norm! V" vim.v.count1 "$y"))
                  :line  (vim.api.nvim_command "norm! `[V`]y")
                  ;:V  (vim.api.nvim_command "norm! `[V`]y")
                  :char  (vim.api.nvim_command "norm! `[v`]y")
                  ;_#     (vim.api.nvim_command (.. "norm! `<" KIND# "`>y"))
                  :block (vim.api.nvim_command "norm! `[<c-v>`]y")
                  _#     (vim.api.nvim_command (.. "norm! `<" KIND# "`>y")) ; double press
                  )
                (let [CONTEXT# (vim.api.nvim_eval "@@")
                      OUTPUT# (,f CONTEXT# KIND#)]
                  (when OUTPUT#
                    (vim.fn.setreg "@" OUTPUT# (vim.fn.getregtype "@"))
                    (vim.api.nvim_command "norm! gv\"0p"))
                  (vim.fn.setreg "@@" REG# (vim.fn.getregtype "@@")))))]
    `(let [VLUA# ,(_vlua op :operator fs)
           RHS_TEXTOBJECT# (.. ":set operatorfunc=" VLUA# "<cr>g@")
           RHS_VISUAL# (.. ":<c-u>call " VLUA# "(visualmode())<cr>")
           LHS_DOUBLE# (.. ,fs (string.sub ,fs -1))
           RHS_DOUBLE# (.. ":<c-u>call " VLUA# "(v:count1)<cr>")]
       (vim.api.nvim_set_keymap "n" ,fs RHS_TEXTOBJECT# {:noremap true :silent true})
       (vim.api.nvim_set_keymap "n" LHS_DOUBLE# RHS_DOUBLE# {:noremap true :silent true})
       (vim.api.nvim_set_keymap "v" ,fs RHS_VISUAL# {:noremap true :silent true}))))

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

;(fn M.def-leader [])

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
