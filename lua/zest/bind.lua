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
local function get_cm(kind, id, t)
  local _0_ = t
  if (_0_ == "expr") then
    return ("v:lua.zestExec('" .. kind .. "', '" .. escape(id) .. "')")
  end
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
M.cm = function(opts, id, ts, args)
  local _0_ = type(ts)
  if (_0_ == "function") then
    local cmd = ("com " .. opts .. " " .. id .. " :call v:lua.zestExec('cm', '" .. escape(id) .. "', " .. args .. ")")
    bind_21("cm", id, ts)
    return vim.api.nvim_command(cmd)
  elseif (_0_ == "string") then
    local cmd = ("com " .. opts .. " " .. id .. " " .. ts)
    return vim.api.nvim_command(cmd)
  end
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
  elseif (_0_ == "string") then
    for m in string.gmatch(modes, ".") do
      vim.api.nvim_set_keymap(m, fs, ts, opts)
    end
    return nil
  end
end
return M