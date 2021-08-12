local M = {}
_G.zest = {keymap = {}, user = {}}
local n = 1
M.concat = function(xs, d)
  local d0 = (d or "")
  if (type(xs) == "string") then
    return xs
  elseif (type(xs) == "number") then
    return tostring(xs)
  else
    return table.concat(xs, d0)
  end
end
M.id = function()
  local id = ("_" .. n)
  n = (n + 1)
  return id
end
local function _vlua(kind, f)
  local id = M.id()
  do end (_G.zest)[kind][id] = f
  return ("v:lua.zest." .. kind .. "." .. id)
end
M.vlua = function(f)
  return _vlua("user", f)
end
M.keymap_id = function(lhs, modes)
  local function _2_(c)
    return string.byte(c)
  end
  return ("k1" .. string.gsub(lhs, "%W", _2_) .. "m0" .. modes)
end
M.keymap_vlua = function(id, opts)
  if opts.expr then
    return ("v:lua.zest.keymap." .. id .. ".f()")
  else
    return (":call v:lua.zest.keymap." .. id .. ".f()<cr>")
  end
end
return M
