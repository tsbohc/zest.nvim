; return if aniseed is detected
(when (or (. vim.g :aniseed#env)
          (not (?. _G :_zest :config :source))
          (not (?. _G :_zest :config :target))
          _G._zest.config.disable-compiler)
  (lua "return"))

; autocmds

(local cmd vim.api.nvim_command)
(local au-selector-fnl (.. _G._zest.config.source "/*.fnl"))
(local au-selector-lua (.. _G._zest.config.source "/*.lua"))

(cmd "augroup neozestcompile")
(cmd "autocmd!")
(cmd (.. "au BufWritePost " au-selector-fnl " :lua require('zest.compile')()"))
(cmd (.. "au BufWritePost " au-selector-lua " :lua require('zest.compile')()"))
(cmd "augroup END")
