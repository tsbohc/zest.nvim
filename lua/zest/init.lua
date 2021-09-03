local function config(xt)
  local conf = {["disable-compiler"] = false, ["verbose-compiler"] = true}
  if xt then
    for k, v in pairs(xt) do
      conf[k] = v
    end
  end
  return conf
end
local function setup(xt)
  _G._zest = {autocmd = {["#"] = 1}, command = {["#"] = 1}, config = config(xt), keymap = {["#"] = 1}, v = {["#"] = 1}}
  return nil
end
local N = 1
_G.zest = (_G.zest or {["#"] = 1, autocmd = {}, keymap = {}, user = {}})
local function id()
  local id0 = N
  N = (N + 1)
  return ("_" .. id0)
end
local function vlua(s, f)
  if (type(f) == "function") then
    local id0 = id()
    local vlua0 = ("v:lua.zest.impure." .. id0)
    do end (_G.zest.impure)[id0] = f
    if s then
      return string.format(s, vlua0)
    else
      return vlua0
    end
  end
end
local function bind(s, data)
  return (vlua(s, data) or data)
end
local function concat(xs, d)
  local d0 = (d or "")
  if (type(xs) == "table") then
    return table.concat(xs, d0)
  elseif (type(xs) == "string") then
    return xs
  end
end
local function def_keymap(mod, opt, lhs, rhs)
  local rhs0
  if opt.expr then
    rhs0 = bind("%s()", rhs)
  else
    rhs0 = bind(":call %s()<cr>", rhs)
  end
  for m in mod:gmatch(".") do
    vim.api.nvim_set_keymap(m, lhs, rhs0, opt)
  end
  return nil
end
local function def_keymap_pairs(mod, opt, xs)
  for lhs, rhs in pairs(xs) do
    def_keymap(mod, opt, lhs, rhs)
  end
  return nil
end
local function def_autocmd(eve, pat, rhs)
  local rhs0 = bind(":call %s()", rhs)
  return vim.cmd(concat({"autocmd", concat(eve, ","), concat(pat, ","), rhs0}, " "))
end
return {["def-autocmd"] = def_autocmd, ["def-keymap"] = def_keymap, ["def-keymap-pairs"] = def_keymap_pairs, def_autocmd = def_autocmd, def_keymap = def_keymap, def_keymap_pairs = def_keymap_pairs, setup = setup, vlua = vlua}
