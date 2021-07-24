(fn xs-str [xs]
  "convert seq of symbols 'xs' to a seq of strings"
  (let [r []]
    (for [i 1 (# xs)]
      (table.insert r `,(tostring (. xs i))))
    r))

; internal

(fn _encode [s]
  "convert characters of string 's' to byte_"
  (if (= (type s) :string)
    `,(.. "_" (string.gsub s "."
                (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))
    `(.. "_" (string.gsub ,s "."
               (fn [ZEST_C#] (string.format "%s_" (string.byte ZEST_C#)))))))

(fn _vlua [f kind id]
  "store function 'f' into _G._zest and return its v:lua"
  (if id
    `(let [ZEST_ID# ,(_encode id)]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))
    `(let [ZEST_ID# (.. "_" (. _G._zest ,kind :#))]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (tset _G._zest ,kind :# (+ (. _G._zest ,kind :#) 1))
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))))

(fn _vlua-format [s f kind id]
  "a string.format wrapper for _vlua"
  `(string.format ,s ,(_vlua f kind id)))

(local M {})

; vlua

(fn M.vlua [f]
  "a user macro for _vlua"
  `,(_vlua f :v))

(fn M.vlua-format [s f]
  "a user macro for _vlua-format"
  `,(_vlua-format s f :v))

; TODO redundant?
;(fn M.def-vlua-fn [s ...]
;  (let [f `(fn ,...)]
;    `,(_vlua-format s f :v)))

; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
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
  "define a new augroup, with or without autocmd!"
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

(fn _autocmd-options [events patterns]
  (let [events (table.concat (xs-str events) ",")
        patterns (if (= (type patterns) :string)
                   patterns
                   (table.concat (xs-str patterns) ","))]
    (values events patterns)))

(fn M.def-autocmd [events patterns ts]
  (let [(events patterns) (_autocmd-options events patterns)]
    `(vim.api.nvim_command (.. "au " ,events " " ,patterns " " ,ts))))

(fn M.def-autocmd-fn [events patterns ...]
  (let [(events patterns) (_autocmd-options events patterns)
        v (_vlua `(fn [] ,...) :autocmd)]
    `(let [ZEST_VLUA# ,v
           ZEST_RHS# (string.format ":call %s()" ZEST_VLUA#)]
       (vim.api.nvim_command (.. "au " ,events " " ,patterns " " ZEST_RHS#)))))

; textobject

;; TODO prep RHS like this wherever else i can
;(fn M.def-textobject [fs ts]
;  `(let [ZEST_RHS# (.. ":<c-u>norm! " ,ts "<cr>")]
;     (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
;     (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true})))
;
;(fn M.def-textobject-fn [fs ...]
;  (let [v (_vlua `(fn [] ,...) :textobject fs)]
;    `(let [ZEST_VLUA# ,v
;           ZEST_RHS# (string.format ":<c-u>call %s()<cr>" ZEST_VLUA#)]
;       (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
;       (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true}))))

; textoperator

;(fn M.def-operator [fs f]
;  (let [op `(fn [KIND#]
;              (let [REG# (vim.api.nvim_eval "@@")
;                    REG_TYPE# (vim.fn.getregtype "@@")
;                    SELECTION# vim.opt.selection
;                    CLIPBOARD# vim.opt.clipboard
;                    KIND# (if (tonumber KIND#) :count KIND#)
;                    C-V# (vim.api.nvim_replace_termcodes "<c-v>" true true true)]
;                (tset vim.opt :selection "inclusive")
;                (: vim.opt.clipboard :remove :unnamed)
;                (: vim.opt.clipboard :remove :unnamedplus)
;                (var INPUT_REG_TYPE# "") ;
;                (match KIND#
;                  :count (do (vim.api.nvim_command (.. "norm! V" vim.v.count1 "$y"))
;                           (set INPUT_REG_TYPE# "l"))  ; count + double
;                  :V     (do (vim.api.nvim_command "norm! gvy")
;                           (set INPUT_REG_TYPE# "l"))  ; v-line
;                  C-V#   (do (vim.api.nvim_command "norm! gvy")
;                           (set INPUT_REG_TYPE# "b"))  ; v-block
;                  :v     (do (vim.api.nvim_command "norm! gvy")
;                           (set INPUT_REG_TYPE# "c"))  ; v-char
;                  :line  (do (vim.api.nvim_command "norm! `[V`]y")
;                           (set INPUT_REG_TYPE# "l"))  ; m-line
;                  :block (do (vim.api.nvim_command "norm! `[<c-v>`]y")
;                           (set INPUT_REG_TYPE# "b"))  ; m-block
;                  :char  (do (vim.api.nvim_command "norm! `[v`]y")
;                           (set INPUT_REG_TYPE# "c"))  ; m-char
;                  )
;                (let [INPUT# (vim.api.nvim_eval "@@")
;                      OUTPUT# (,f INPUT# KIND#)]
;                  (when OUTPUT#
;                    (vim.fn.setreg "@" OUTPUT# INPUT_REG_TYPE#)
;                    (vim.api.nvim_command "norm! gvp"))
;                  (vim.fn.setreg "@@" REG# REG_TYPE#)
;                  (tset vim.opt :selection SELECTION#)
;                  (tset vim.opt :clipboard CLIPBOARD#))))]
;    `(let [VLUA# ,(_vlua op :operator fs)
;           RHS_TEXTOBJECT# (.. ":set operatorfunc=" VLUA# "<cr>g@")
;           RHS_VISUAL# (.. ":<c-u>call " VLUA# "(visualmode())<cr>")
;           LHS_DOUBLE# (.. ,fs (string.sub ,fs -1))
;           RHS_DOUBLE# (.. ":<c-u>call " VLUA# "(v:count1)<cr>")]
;       (vim.api.nvim_set_keymap "n" ,fs RHS_TEXTOBJECT# {:noremap true :silent true})
;       (vim.api.nvim_set_keymap "n" LHS_DOUBLE# RHS_DOUBLE# {:noremap true :silent true})
;       (vim.api.nvim_set_keymap "v" ,fs RHS_VISUAL# {:noremap true :silent true}))))

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
