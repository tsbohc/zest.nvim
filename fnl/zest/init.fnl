(local M {})

(fn M.setup []
  (tset _G :ZEST (or _G.ZEST {:keymap  {} :autocmd {}})))

M
