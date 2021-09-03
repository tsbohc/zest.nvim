; I need some fancy pcaller instead of straight v:lua
; although that breaks mapping operator functions

; what i could do though, use the same index as param trick to
; translate v:vlua.zest._1 to (pcall (. state "_1"))
; or just wrap every stored function in a pcaller

;(fn _G.zcall [idx]
;  (let [data (. state idx)]
;    (print (vim.inspect data))))

; v:lua.zcall('_3') ; don't do this! see above

; TODO maybe store data locally in state?
; and expose it for viewing via a global fn?

; TODO abstract bind? e.g (bind opt rhs)
; and have bind figure out what it was passed

(local state {:# 1})

(global lime {})

; TODO make this fancy
; autocmd eve pat fn_id
; keymap mod opt lhs fn_id
(fn inspect []
  (print (vim.inspect state)))

(fn idx []
  "return a unique, commandmode-safe ordered id"
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
                 {:kind "keymap" :opt {:expr false}}
                 (.. ":call " vlua "()<cr>")
                 {:kind "autocmd"}
                 (.. ":call " vlua "()"))]
      (set data.fn data.rhs)
      (set data.rhs vlua)
      (tset lime idx data)
      data)
    (do
      (tset lime idx data)
      data)))

;; keymap

(fn def-keymap [mod opt lhs rhs]
  (let [data (bind {:kind "keymap" : mod : opt : lhs : rhs})]
    (each [m (data.mod:gmatch ".") ]
      (vim.api.nvim_set_keymap m data.lhs data.rhs data.opt))
    ))



; ensure lua compatibility

(local F
  {
   : bind
   : def-keymap
   : def-autocmd
   })

(local M F)

(each [k v (pairs F)]
  (tset M (k:gsub "-" "_") v))

M
