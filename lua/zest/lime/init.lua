local M = {}
_G.zest = (_G.zest or {keymap = {}, user = {}})
local n = 1
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
return M
