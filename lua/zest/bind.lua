local M = {}
local ki = {}
local function strip(s)
  return s:gsub("[<>-]", {["-"] = "_dash_", ["<"] = "_left_angle_bracket_", [">"] = "_right_angle_bracket_"})
end
local function reverse_strip(s)
  return string.gsub(string.gsub(string.gsub(s, "_left_angle_bracket_", "<"), "_right_angle_bracket_", ">"), "_dash_", "-")
end
_G.__ki_execute_map = function(id)
  local f = ki[id]
  local ok_3f, result = pcall(f)
  if not ok_3f then
    return error(("\n[ ki- ]: error while executing mapping '" .. reverse_strip(id) .. "':\n" .. result))
  else
    return result
  end
end
local function bind(modes, fs, ts, opts)
  if (nil ~= fs) then
    local _0_ = type(ts)
    if (_0_ == "function") then
      local id = strip(fs)
      local cmd
      if opts.expr then
        cmd = ("v:lua.__ki_execute_map('" .. id .. "')")
      else
        cmd = (":lua _G.__ki_execute_map('" .. id .. "')<cr>")
      end
      ki[id] = ts
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
  return bind(...)
end
setmetatable(M, {__call = _0_})
return M