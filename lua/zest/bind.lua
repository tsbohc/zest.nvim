local M = {}
local function strip(s)
  return s:gsub("[<>-]", {["-"] = "_dash_", ["<"] = "_left_angle_bracket_", [">"] = "_right_angle_bracket_"})
end
local function reverse_strip(s)
  return string.gsub(string.gsub(string.gsub(s, "_left_angle_bracket_", "<"), "_right_angle_bracket_", ">"), "_dash_", "-")
end
local state = {cm = {}, ki = {}}
M.bind = function(kind, id, f)
  state[kind][id] = f
  return nil
end
_G.zestExec = function(kind, id, ...)
  local f = state[kind][id]
  local ok_3f, result = pcall(f, ...)
  if not ok_3f then
    return error(("\n<zest:" .. kind .. "> error while executing '" .. reverse_strip(id) .. "':\n" .. result))
  else
    return result
  end
end
M["create-cmd"] = function(name)
  return vim.api.nvim_command(("com! " .. name .. " :lua _G.zestExec(\"cm\", \"" .. name .. "\")"))
end
M["create-map"] = function(modes, fs, ts, opts)
  if (nil ~= fs) then
    local _0_ = type(ts)
    if (_0_ == "function") then
      local id = strip(fs)
      local cmd
      if opts.expr then
        cmd = ("v:lua.zestExec('ki', '" .. id .. "')")
      else
        cmd = (":lua _G.zestExec('ki', '" .. id .. "')<cr>")
      end
      M.bind("ki", id, ts)
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