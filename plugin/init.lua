local _0_
do
  local t_0_ = _G
  if (nil ~= t_0_) then
    t_0_ = (t_0_)._zest
  end
  if (nil ~= t_0_) then
    t_0_ = (t_0_).config
  end
  if (nil ~= t_0_) then
    t_0_ = (t_0_).source
  end
  _0_ = t_0_
end
local _1_
do
  local t_1_ = _G
  if (nil ~= t_1_) then
    t_1_ = (t_1_)._zest
  end
  if (nil ~= t_1_) then
    t_1_ = (t_1_).config
  end
  if (nil ~= t_1_) then
    t_1_ = (t_1_).target
  end
  _1_ = t_1_
end
if (vim.g["aniseed#env"] or not _0_ or not _1_ or _G._zest.config["disable-compiler"]) then
  return
end
local cmd = vim.api.nvim_command
local au_selector = (_G._zest.config.source .. "/*.fnl")
cmd("augroup neozestcompile")
cmd("autocmd!")
cmd(("au BufWritePost " .. au_selector .. " :lua require('zest.compile')()"))
return cmd("augroup END")
