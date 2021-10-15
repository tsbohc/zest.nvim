; I need some fancy pcaller instead of straight v:lua
; although that breaks mapping operator functions

; what i could do though, use the same index as param trick to
; translate v:vlua.zest._1 to (pcall (. state "_1"))
; or just wrap every stored function in a pcaller

;(fn _G.zcall [idx]
;  (let [data (. state idx)]
;    (print (vim.inspect data))))

; v:lua.zcall('_3') ; don't do this! see above

(local state {:# 1})

(global lime {})

(fn inspect []
  (print (vim.inspect state)))

(fn idx []
  "return a ordered, commandmode-safe id"
  (let [id state.#]
    (set state.# (+ id 1))
    (.. "_" id)))

(fn bind [data]
  "bind a data table and return its vlua"
  (if (= (type data.rhs) :function)
    (let [idx (idx)
          vlua (.. "v:lua.lime." idx ".fn")
          vlua (match data
                 {:kind "keymap" :opt {:expr true}}
                 (.. vlua "()")
                 {:kind "keymap"}
                 (.. ":call " vlua "()<cr>")
                 {:kind "autocmd"}
                 (.. ":call " vlua "()")
                 {:kind "user"}
                 vlua)]
      (set data.fn data.rhs)
      (set data.rhs vlua)
      (tset lime idx data)
      data)
    (do
      (tset lime idx data)
      data)))

(fn concat [xs d]
  (let [d (or d "")]
    (if (= (type xs) :table)
      (table.concat xs d)
      xs)))

;; vlua

(fn vlua [f]
  (let [data (bind {:kind "user" :rhs f})]
    data.rhs))

(fn vlua-format [s f]
  (string.format s (vlua f)))

;; keymap

(fn def-keymap [mod opt lhs rhs]
  (let [data (bind {:kind "keymap" : mod : opt : lhs : rhs})]
    (each [m (data.mod:gmatch ".") ]
      (vim.api.nvim_set_keymap m data.lhs data.rhs data.opt))))

;; autocmd

(fn def-autocmd [eve pat rhs]
  (let [data (bind {:kind "autocmd" : eve : pat : rhs})]
    (vim.cmd (.. "autocmd "
                 (concat data.eve ",") " "
                 (concat data.pat ",") " "
                 data.rhs " "))))

(fn def-augroup [name f]
  (vim.cmd (concat ["augroup " name] " "))
  (vim.cmd "autocmd!") ; TODO dirty stuff
  (when f (f))
  (vim.cmd "augroup END"))

; convert the names to lua compatible ones

(local F
  {
   : vlua
   : vlua-format
   : def-keymap
   : def-augroup
   : def-autocmd
   })

(local M F)

(each [k v (pairs F)]
  (tset M (k:gsub "-" "_") v))

M
