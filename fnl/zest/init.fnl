;; {{{
(fn config [xt]
  (let [conf {:verbose-compiler true
              :disable-compiler false}]
    (when xt
      (each [k v (pairs xt)]
        (tset conf k v)))
    conf))

(fn setup [xt]
  (set _G._zest
       {:keymap {:# 1}
        :command {:# 1}
        :autocmd {:# 1}
        :v {:# 1}
        :config (config xt)}))
; }}}

; I need some fancy pcaller instead of straight v:lua

(var N 1)

; initialise _G.zest
(set _G.zest
     (or _G.zest
         {:# 1 :keymap {} :autocmd {} :user {}}))

(fn id []
  (let [id N]
    (set N (+ N 1))
    (.. "_" id)))

(fn vlua [s f]
  (when (= (type f) :function)
    (let [id (id)
          vlua (.. "v:lua.zest.impure." id)]
      (tset _G.zest.impure id f)
      (if s
        (string.format s vlua)
        vlua))))

; i should probably make this the default behavior of vlua
(fn bind [s data]
  "return a formatted vlua or the passed string"
  (or (vlua s data)
      data))

(fn concat [xs d]
  (let [d (or d "")]
    (if (= (type xs) :table)
      (table.concat xs d)
      (= (type xs) :string)
      xs)))

;; keymaps

(fn def-keymap [mod opt lhs rhs]
  (let [rhs (if opt.expr
              (bind "%s()" rhs)
              (bind ":call %s()<cr>" rhs))]
    (each [m (mod:gmatch ".") ]
      (vim.api.nvim_set_keymap m lhs rhs opt))))

(fn def-keymap-pairs [mod opt xs]
  (each [lhs rhs (pairs xs)]
    (def-keymap mod opt lhs rhs)))

;; autocmd

(fn def-autocmd [eve pat rhs]
  (let [rhs (bind ":call %s()" rhs)]
    (vim.cmd (concat ["autocmd" (concat eve ",") (concat pat ",") rhs] " "))))

; TODO automate this
; or just use lua-compatible names
; ehhh, no, I want both

{
 : vlua
 : def-keymap         :def_keymap def-keymap
 : def-keymap-pairs   :def_keymap_pairs def-keymap-pairs
 : def-autocmd        :def_autocmd def-autocmd

 : setup
 }
