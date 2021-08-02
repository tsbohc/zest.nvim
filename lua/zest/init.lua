local M = {}
local function decode(bytes)
  local s = ""
  for b in bytes:gmatch("([^_]+)") do
    s = (s .. string.char(b))
  end
  return s
end
local function encode(s)
  local function _0_(c)
    return (string.byte(c) .. "_")
  end
  return ("_" .. string.gsub(s, ".", _0_))
end
local function wrap(kind, id, f)
  local ok_3f, out = pcall(f)
  if not ok_3f then
    local f0 = require("zest.fennel")
    return print(("\nzest: error while executing " .. kind .. " '" .. decode(id) .. "':\n" .. out))
  else
    return out
  end
end
local function new_xt(kind)
  local function _0_(xt, k, v)
    return rawset(xt, k, v)
  end
  return setmetatable({["#kind"] = kind}, {__newindex = _0_})
end
local function store(f, kind, id)
  if id then
    local id0 = encode(id)
    local function _0_()
      return wrap(kind, id0, f)
    end
    _G._zest[kind][id0] = _0_
    return ("v:lua._zest." .. kind .. "." .. id0)
  end
end
local function config(xt)
  local conf = {["disable-compiler"] = false, ["verbose-compiler"] = true}
  if xt then
    for k, v in pairs(xt) do
      conf[k] = v
    end
  end
  return conf
end
M.setup = function(xt)
  _G._zest = {autocmd = {["#"] = 1}, command = {}, config = config(xt), keymap = {}, operator = {}, store = store, textobject = {}, v = {["#"] = 1}}
  return nil
end
return M
