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

(fn _v-lua [f kind id]
  (if id
    `(let [ZEST_ID# ,(_encode id)]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))
    `(let [ZEST_ID# (.. "_" (. _G._zest ,kind :#))]
       (tset _G._zest ,kind ZEST_ID# ,f)
       (tset _G._zest ,kind :# (+ (. _G._zest ,kind :#) 1))
       (.. ,(.. "v:lua._zest." kind ".") ZEST_ID#))))

(fn _v-lua-format [s f kind id]
  `(string.format ,s ,(_v-lua f kind id)))

(local M {})

; v-lua

(fn M.v-lua [f]
  `,(_v-lua f :v))

(fn M.v-lua-format [s f]
  `,(_v-lua-format s f :v))

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
        v (_v-lua `(fn [] ,...) :keymap fs)]
    `(let [ZEST_V_LUA# ,v
           ZEST_RHS# (string.format ,(if opts.expr "%s()" ":call %s()<cr>") ZEST_V_LUA#)]
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

(fn M.def-autocmd [pattern events ts]
  (let [events (table.concat (xs-str events) ",")]
    `(vim.api.nvim_command (.. "au " ,events " " ,pattern " " ,ts))))

(fn M.def-autocmd-fn [pattern events ...]
  (let [events (table.concat (xs-str events) ",")
        v (_v-lua `(fn [] ,...) :autocmd)]
    `(let [ZEST_V_LUA# ,v
           ZEST_RHS# (string.format ":call %s()" ZEST_V_LUA#)]
       (vim.api.nvim_command (.. ,(.. "au " events " " ) ,pattern " " ZEST_RHS#)))))

; textobject

; TODO prep RHS like this wherever else i can
(fn M.def-textobject [fs ts]
  `(let [ZEST_RHS# (.. ":<c-u>norm! " ,ts "<cr>")]
     (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
     (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true})))

(fn M.def-textobject-fn [fs ...]
  (let [v (_v-lua `(fn [] ,...) :textobject fs)]
    `(let [ZEST_V_LUA# ,v
           ZEST_RHS# (string.format ":<c-u>call %s()<cr>" ZEST_V_LUA#)]
       (vim.api.nvim_set_keymap "x" ,fs ZEST_RHS# {:noremap true :silent true})
       (vim.api.nvim_set_keymap "o" ,fs ZEST_RHS# {:noremap true :silent true}))))


; setoption bakery

;opt-set      opt-local-set      opt-global-set
;opt-get      opt-local-get      opt-global-get
;opt-append   opt-local-append   opt-global-append
;opt-prepend  opt-local-prepend  opt-global-prepend
;opt-remove   opt-local-remove   opt-global-remove

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
