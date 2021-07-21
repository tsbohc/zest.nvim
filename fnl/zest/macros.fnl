(fn xs-str [xs]
  "convert seq of symbols 'xs' to a seq of strings"
  (let [r []]
    (for [i 1 (# xs)]
      (table.insert r `,(tostring (. xs i))))
    r))

(local M {})

; setup

(fn M.zest-setup []
  `(do
     (tset _G :_zest {})
     (tset _G :_zest :keymap {})))

; setoption

(fn M.get-option [key]
  ; FIXME opt:get errors out on unset options, so here's an ugly thing
  (let [key (tostring key)]
    `(let [(ok?# val#) (pcall (fn [] (: (. vim.opt ,key) :get)))]
       (if ok?# val# nil))))

(fn M.set-option [key val]
  (let [key (tostring key)
        val (if (= nil val) true val)
        (key act) (if (key:find ":")
                    (key:match "(%w+):(%w+)")
                    (values key nil))
        opt `(. vim.opt ,key)]
    (match act
      nil      `(tset vim.opt ,key ,val)
      "toggle" `(tset vim.opt ,key (not (opt-get ,key)))
      _        `(: ,opt ,act ,val))))

; keymap

(fn keymap-options [args]
  "convert seq of options 'args' to modes string and keymap option dict"
  (let [modes (tostring (table.remove args 1))
        opts-xs (xs-str args)
        opts {:noremap true}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn encode-special [s]
  (.. "_" (string.gsub (tostring s) "%W" (fn [c] (string.format "_%02X_" (string.byte c))))))

; FIXME creates duplicates of the character function every time ,id is used
; not sure if that big of a deal since it only affects function mappping to variables or expressions
(fn encode-special-macro [s]
  `(.. "_" (string.gsub ,s "%W" (fn [c#] (string.format "_%02X_" (string.byte c#))))))

; FIXME broken, generates new id every time?
(fn hash [s]
  (var h 0)
  (each [c (string.gmatch s ".")]
    (set h (+ (* 31 h) (string.byte c))))
  h)

(fn M.def-keymap-fn [fs args ...]
  (let [(modes opts) (keymap-options args)
        f `(fn [] ,...)
        id (if (= (type fs) :string)
             (encode-special fs)
             `,(encode-special-macro fs))
        ts (if opts.expr
             `(.. "v:lua._zest.keymap." ,id "()")
             `(.. ":call v:lua._zest.keymap." ,id "()<cr>"))
        out []]
    (each [m (string.gmatch modes ".")]
      (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts)))
    `(do
       (tset _G :_zest :keymap ,id ,f)
       (do ,(unpack out)))))

(fn M.def-keymap [...]
  (match (# [...])
    3 (let [(fs args ts) (unpack [...])
            (modes opts) (keymap-options args)
            out []]
        (each [m (string.gmatch modes ".")]
          (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts)))
        `(do
           ,(unpack out)))
    2 (let [(args xt) (unpack [...])
            (modes opts) (keymap-options args)
            out []]
        (each [fs ts (pairs xt)]
          (each [m (string.gmatch modes ".")]
            (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts))))
        `(do
           ,(unpack out)))))

; NOTE deprecating literal binding
;(fn M.keymap-literal [fs args ts]
;  (let [(modes opts) (keymap-options args)
;        out []]
;    (each [m (string.gmatch modes ".")]
;      (table.insert out `(vim.api.nvim_set_keymap ,m ,(tostring fs) ,(tostring ts) ,opts)))
;    `(do
;       ,(unpack out))))

; autocmd

(fn _create-augroup [clear? name ...]
  (let [out []]
    (when clear?
      (table.insert out `(vim.api.nvim_command "autocmd!")))
    `(do
       (vim.api.nvim_command (.. "augroup " ,name))
       ,(unpack out)
       (do ,...)
       (vim.api.nvim_command (.. "augroup END")))))

(fn M.def-augroup [name ...]
  (_create-augroup true name ...))

(fn M.def-augroup-dirty [name ...]
  (_create-augroup false name ...))

(fn M.def-autocmd [pattern events ts]
  (let [events (table.concat (xs-str events) ",")]
    `(vim.api.nvim_command (.. "au " ,events " " ,pattern " " ,ts))))

; NOTE this will add a new batch of autocmd functions when a file is recompiled
; but they will crear up when vim is reopened
(var au-id 0)

(fn M.def-autocmd-fn [pattern events ...]
  (let [events (table.concat (xs-str events) ",")
        f `(fn [] ,...)
        ;id `,(encode-special (.. (hash (: (tostring ...) :gsub "table: %S+ " "")) "_" pattern))
        id (.. "_au_" au-id)
        ts `,(.. ":call v:lua._zest.autocmd." id "()")]
    (set au-id (+ au-id 1))
    `(do
       (tset _G :_zest :autocmd ,id ,f)
       (vim.api.nvim_command (.. "au " ,events " " ,pattern " " ,ts)))))

;(fn M.keymap-leader [])

; v-lua

; TODO!! i need to switch everything to this
(fn M.v-lua [f]
  `(let [n# (. _G._zest.v :__count)
         id# (.. "_" n#)]
     (tset _G._zest.v :__count (+ n# 1))
     (tset _G._zest.v id# ,f)
     (.. "v:lua._zest.v." id#)))

(fn M.v-lua-format [s f]
  `(string.format ,s ,(M.v-lua f)))


; packer

(fn M.packer-use-wrapper [repo opts]
  (let [xt [repo]]
    (when opts
      ; FIXME needs to be a deep copy
      (each [k v (pairs opts)]
        (tset xt k v)))
    `(use ,xt)))

; neovim api

(fn M.let-g [k v]
  "set 'k' to 'v' on vim.g table"
  `(tset vim.g ,(tostring k) ,v))

M
