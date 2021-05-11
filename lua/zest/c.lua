local M = {}
_G["ki"] = {}
local function bind(modes, fs, ts, opts)
  local _0_ = type(ts)
  if (_0_ == "function") then
    local id = fs
    local cmd
    if opts.expr then
      cmd = ("v:lua.ki." .. id .. "()")
    else
      cmd = (":lua _G.ki." .. id .. "()<cr>")
    end
    _G.ki[id] = ts
    for m in string.gmatch(modes, ".") do
      vim.api.nvim_set_keymap(m, fs, cmd, opts)
    end
    return nil
  elseif (_0_ == "string") then
    local cmd = ts
    for m in string.gmatch(modes, ".") do
      vim.api.nvim_set_keymap(m, fs, cmd, opts)
    end
    return nil
  end
end
local function _0_(_, ...)
  return bind(...)
end
setmetatable(M, {__call = _0_})
return M