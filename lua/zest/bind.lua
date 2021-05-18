local M = {}
local function escape(s)
  return s:gsub("[<>]", {["<"] = "\\<", [">"] = "\\>"})
end
local state = {cm = {}, ki = {}}
local function bind_21(kind, id, f)
  local id_esc = escape(id)
  state[kind][id_esc] = f
  return ("v:lua.zestExec('" .. kind .. "', '" .. id_esc .. "')")
end
_G.zestExec = function(kind, id_esc, ...)
  local f = state[kind][id_esc]
  local id = string.gsub(string.gsub(id_esc, "\\<", "<"), "\\>", ">")
  local ok_3f, result = pcall(f, ...)
  if not ok_3f then
    return error(("\n<zest:" .. kind .. "> error while executing '" .. id .. "':\n" .. result))
  else
    return result
  end
end
M.cm = function(id, f)
  return vim.api.nvim_command(("com! " .. id .. " :call " .. bind_21("cm", id, f)))
end
M.ki = function(modes, fs, ts, opts)
  local _0_ = type(ts)
  if (_0_ == "function") then
    local ex
    if opts.expr then
      ex = bind_21("ki", fs, ts)
    else
      ex = (":call " .. bind_21("ki", fs, ts) .. "<cr>")
    end
    for m in string.gmatch(modes, ".") do
      vim.api.nvim_set_keymap(m, fs, ex, opts)
    end
    return nil
  end
end
M["create-map"] = function(modes, fs, ts, opts)
  if (nil ~= fs) then
    local _0_ = type(ts)
    if (_0_ == "function") then
      local cmd
      if opts.expr then
        cmd = bind_21("ki", fs, ts)
      else
        cmd = (":call " .. bind_21("ki", fs, ts) .. "<cr>")
      end
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
    else
      local _ = _0_
      return print(("<zest:ki> unhandled type '" .. type(ts) .. "' of right side in binding '" .. fs .. "'"))
    end
  else
    if (nil ~= ts) then
      return print("<zest:ki> left side of a binding evaluated to nil!")
    else
      return print("<zest:ki> both sides of a binding evaluated to nil!")
    end
  end
end
local function _0_(_, ...)
  return M["create-map"](...)
end
setmetatable(M, {__call = _0_})
return M