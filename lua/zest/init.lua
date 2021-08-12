local M = {}
local function config(xt)
  local conf = {["disable-compiler"] = false, ["verbose-compiler"] = true}
  if xt then
    for k, v in pairs(xt) do
      conf[k] = v
    end
  end
  return conf
end
_G.___zest_inspect = function()
  return print(vim.inspect(_G._zest))
end
M.setup = function(xt)
  vim.cmd(":command! ZestInspect :call v:lua.___zest_inspect()")
  _G._zest = {autocmd = {["#"] = 1}, command = {["#"] = 1}, config = config(xt), keymap = {["#"] = 1}, v = {["#"] = 1}}
  return nil
end
return M
