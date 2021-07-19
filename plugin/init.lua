if vim.g["aniseed#env"] then
  return
end
local cmd = vim.api.nvim_command
local au_selector = vim.fn.resolve((vim.fn.stdpath("config") .. "/fnl/*.fnl"))
cmd("augroup neozestcompile")
cmd("autocmd!")
cmd(("au BufWritePost " .. au_selector .. " :lua require('zest.compile')()"))
return cmd("augroup END")
