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
     (tset _G :ZEST {})
     (tset _G :ZEST :keymap {})))

; setoption

(fn opt-get [key]
  ; :get errors out on unset options, so here's an ugly thing
  (let [key (tostring key)]
    `(let [(ok?# val#) (pcall (fn [] (: (. vim.opt ,key) :get)))]
       (if ok?# val# nil))))

(fn M.setoption [key val]
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
  (s:gsub "%W" (fn [c] (string.format "_%02X_" (string.byte c)))))

; FIXME creates duplicates of the character function every time ,id is used
; not sure if that big of a deal since it only affects function mappping to variables or expressions
(fn encode-special-macro [s]
  `(string.gsub ,s "%W" (fn [c#] (string.format "_%02X_" (string.byte c#)))))

(fn M.keymap-function [fs args ...]
  (let [(modes opts) (keymap-options args)
        f `(fn [] ,...)
        id (if (= (type fs) :string)
             (encode-special fs)
             `,(encode-special-macro fs))
        ts (if opts.expr
             `(.. "v:lua.ZEST.keymap." ,id "()")
             `(.. ":call v:lua.ZEST.keymap." ,id "()<cr>"))
        out []]
    (each [m (string.gmatch modes ".")]
      (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts)))
    `(do
       (tset _G :ZEST :keymap ,id ,f)
       (do ,(unpack out)))))

(fn M.keymap-normal [...]
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

(fn M.keymap-literal [fs args ts]
  (let [(modes opts) (keymap-options args)
        out []]
    (each [m (string.gmatch modes ".")]
      (table.insert out `(vim.api.nvim_set_keymap ,m ,(tostring fs) ,(tostring ts) ,opts)))
    `(do
       ,(unpack out))))

;(fn M.keymap-leader [])

M
