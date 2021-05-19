local M = {}
local function escape(s)
  return s:gsub("[<>]", {["<"] = "\\<", [">"] = "\\>"})
end
local function un_escape(s)
  return string.gsub(string.gsub(s, "\\<", "<"), "\\>", ">")
end
local state = {cm = {}, ki = {}}
local function bind_21(kind, id, f)
  local id_esc = escape(id)
  state[kind][id_esc] = f
  return ("v:lua.zestExec('" .. kind .. "', '" .. id_esc .. "')")
end
_G.zestExec = function(kind, id_esc, ...)
  local f = state[kind][id_esc]
  local id = un_escape(id_esc)
  local ok_3f, result = pcall(f, ...)
  if not ok_3f then
    return error(("\nzest." .. kind .. "- error while executing '" .. id .. "':\n" .. result))
  else
    return result
  end
end
local function check(kind, fs, ts)
  local _0_ = {fs, ts}
  if ((type(_0_) == "table") and ((_0_)[1] == nil) and ((_0_)[2] == nil)) then
    return print(("zest." .. kind .. "- both sides of a binding evaluated to nil!"))
  elseif ((type(_0_) == "table") and (nil ~= (_0_)[1]) and ((_0_)[2] == nil)) then
    local x = (_0_)[1]
    return print(("zest." .. kind .. "- attempt to bind nil to '" .. tostring(fs) .. "'!"))
  elseif ((type(_0_) == "table") and ((_0_)[1] == nil) and (nil ~= (_0_)[2])) then
    local y = (_0_)[2]
    return print(("zest." .. kind .. "- attempt to bind '" .. tostring(ts) .. "' to nil!"))
  else
    local _ = _0_
    return true
  end
end
M.cm = function(opts, id, ts, args)
  if check("cm", id, ts) then
    local _0_ = type(ts)
    if (_0_ == "function") then
      local cmd = ("com " .. opts .. " " .. id .. " :call v:lua.zestExec('cm', '" .. id .. "', " .. args .. ")")
      bind_21("cm", id, ts)
      return vim.api.nvim_command(cmd)
    elseif (_0_ == "string") then
      local cmd = ("com " .. opts .. " " .. id .. " " .. ts)
      return vim.api.nvim_command(cmd)
    end
  end
end
M.ki = function(modes, fs, ts, opts)
  if check("ki", fs, ts) then
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
    elseif (_0_ == "string") then
      for m in string.gmatch(modes, ".") do
        vim.api.nvim_set_keymap(m, fs, ts, opts)
      end
      return nil
    end
  end
end
return M