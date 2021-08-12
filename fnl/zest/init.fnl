(local M {})

(fn config [xt]
  (let [conf {:verbose-compiler true
              :disable-compiler false}]
    (when xt
      (each [k v (pairs xt)]
        (tset conf k v)))
    conf))

(fn _G.___zest_inspect []
  (print (vim.inspect _G._zest)))

(fn M.setup [xt]
  (vim.cmd ":command! ZestInspect :call v:lua.___zest_inspect()")

  (set _G._zest
       {:keymap {:# 1}
        :command {:# 1}
        :autocmd {:# 1}
        :v {:# 1}
        :config (config xt)}))

M
