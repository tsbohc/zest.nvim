local _2_
do
  local t_1_ = _G
  if (nil ~= t_1_) then
    t_1_ = (t_1_)._zest
  end
  if (nil ~= t_1_) then
    t_1_ = (t_1_).config
  end
  if (nil ~= t_1_) then
    t_1_ = (t_1_).source
  end
  _2_ = t_1_
end
local _7_
do
  local t_6_ = _G
  if (nil ~= t_6_) then
    t_6_ = (t_6_)._zest
  end
  if (nil ~= t_6_) then
    t_6_ = (t_6_).config
  end
  if (nil ~= t_6_) then
    t_6_ = (t_6_).target
  end
  _7_ = t_6_
end
if (vim.g["aniseed#env"] or not _2_ or not _7_ or _G._zest.config["disable-compiler"]) then
  return
end
local cmd = vim.api.nvim_command
local au_selector_fnl = (_G._zest.config.source .. "/*.fnl")
local au_selector_lua = (_G._zest.config.source .. "/*.lua")
cmd("augroup neozestcompile")
cmd("autocmd!")
cmd(("au BufWritePost " .. au_selector_fnl .. " :lua require('zest.compile')()"))
cmd(("au BufWritePost " .. au_selector_lua .. " :lua require('zest.compile')()"))
return cmd("augroup END")
