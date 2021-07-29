(local M {})

(fn M.def-test [name ...]
  `(tset _G :zest_tests ,(tostring name) (fn ,name [] ,...)))

(fn M.def-keymap-test [description fs args ts]
  `(do
     ;(t.? (not vim.g.zest_received) "var not set")
     (def-keymap ,fs ,args ,ts)
     (rinput "<F4>")
     (t.? vim.g.zest_received ,description)
     (tset vim.g :zest_received false)))

(fn M.def-keymap-pairs-test [description args tab]
  `(do
     ;(t.? (not vim.g.zest_received) "var not set")
     (def-keymap ,args ,tab)
     (rinput "<F4>")
     (t.? vim.g.zest_received ,description)
     (tset vim.g :zest_received false)))

(fn M.def-keymap-fn-test [description fs args ...]
  `(do
     (clear)
     (def-keymap-fn ,fs ,args ,...)
     (rinput "<F4>")
     (t.? vim.g.zest_received ,description)
     (tset vim.g :zest_received false)))

(fn M.def-autocmd-test [description events selector ts]
  `(do
     ;(t.? (not vim.g.zest_received) "var not set")
     (def-augroup :ZestTestAugroup
       (def-autocmd ,events ,selector ,ts))
     (vim.cmd "doautocmd User ZestTestUserEvent")
     (t.? vim.g.zest_received ,description)
     (tset vim.g :zest_received false)))

(fn M.def-autocmd-fn-test [description events selector ...]
  `(do
     ;(t.? (not vim.g.zest_received) "var not set")
     (clear)
     (def-augroup :ZestTestAugroup
       (def-autocmd-fn ,events ,selector ,...))
     (vim.cmd "doautocmd User ZestTestUserEvent")
     (t.? vim.g.zest_received ,description)
     (tset vim.g :zest_received false)))

M
