(local M {})

(fn M.setup []
  (tset _G :_zest (or _G.ZEST {:keymap {}
                               :autocmd {}
                               :statusline {}
                               :v {:__count 1}})))

M
