if (vim.g["aniseed#env"] or not _G._zest or _G._zest.config["disable-compiler"]) then
  return
end
local cmd = vim.api.nvim_command
local au_selector = (_G._zest.config.source .. "/*.fnl")
cmd("augroup neozestcompile")
cmd("autocmd!")
cmd(("au BufWritePost " .. au_selector .. " :lua require('zest.compile')()"))
return cmd("augroup END")
