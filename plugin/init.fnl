; return if aniseed is detected
(when (. vim.g :aniseed#env)
  (lua "return"))

; autocmds

(local cmd vim.api.nvim_command)
(local au-selector (vim.fn.resolve (.. (vim.fn.stdpath :config) "/fnl/*.fnl")))

(cmd "augroup neozestcompile")
(cmd "autocmd!")
(cmd (.. "au BufWritePost " au-selector " :lua require('zest.compile')()"))
(cmd "augroup END")
