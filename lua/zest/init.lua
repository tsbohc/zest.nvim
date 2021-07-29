local M = {}
local function decode(bytes)
  local s = ""
  for b in bytes:gmatch("([^_]+)") do
    s = (s .. string.char(b))
  end
  return s
end
local function wrap(kind, id, f)
  local ok_3f, out = pcall(f)
  if not ok_3f then
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
  _G._zest = {autocmd = {["#"] = 1}, command = {}, config = config(xt), keymap = {}, operator = {}, textobject = {}, v = {["#"] = 1}}
  return nil
end
return M
