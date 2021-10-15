local state = {["#"] = 1}
lime = {}
local function inspect()
  return print(vim.inspect(state))
end
local function idx()
  local id = state["#"]
  state["#"] = (id + 1)
  return ("_" .. id)
end
local function bind(data)
  if (type(data.rhs) == "function") then
    local idx0 = idx()
    local vlua = ("v:lua.lime." .. idx0 .. ".fn")
    local vlua0
    do
      local _1_ = data
      if ((type(_1_) == "table") and ((type((_1_).opt) == "table") and (((_1_).opt).expr == true)) and ((_1_).kind == "keymap")) then
        vlua0 = (vlua .. "()")
      elseif ((type(_1_) == "table") and ((_1_).kind == "keymap")) then
        vlua0 = (":call " .. vlua .. "()<cr>")
      elseif ((type(_1_) == "table") and ((_1_).kind == "autocmd")) then
        vlua0 = (":call " .. vlua .. "()")
      elseif ((type(_1_) == "table") and ((_1_).kind == "user")) then
        vlua0 = vlua
      else
      vlua0 = nil
      end
    end
    data.fn = data.rhs
    data.rhs = vlua0
    lime[idx0] = data
    return data
  else
    lime[idx] = data
    return data
  end
end
local function concat(xs, d)
  local d0 = (d or "")
  if (type(xs) == "table") then
    return table.concat(xs, d0)
  else
    return xs
  end
end
local function vlua(f)
  local data = bind({kind = "user", rhs = f})
  return data.rhs
end
local function vlua_format(s, f)
  return string.format(s, vlua(f))
end
local function def_keymap(mod, opt, lhs, rhs)
  local data = bind({kind = "keymap", lhs = lhs, mod = mod, opt = opt, rhs = rhs})
  for m in (data.mod):gmatch(".") do
    vim.api.nvim_set_keymap(m, data.lhs, data.rhs, data.opt)
  end
  return nil
end
local function def_autocmd(eve, pat, rhs)
  local data = bind({eve = eve, kind = "autocmd", pat = pat, rhs = rhs})
  return vim.cmd(("autocmd " .. concat(data.eve, ",") .. " " .. concat(data.pat, ",") .. " " .. data.rhs .. " "))
end
local function def_augroup(name, f)
  vim.cmd(concat({"augroup ", name}, " "))
  vim.cmd("autocmd!")
  if f then
    f()
  end
  return vim.cmd("augroup END")
end
local F = {["def-augroup"] = def_augroup, ["def-autocmd"] = def_autocmd, ["def-keymap"] = def_keymap, ["vlua-format"] = vlua_format, vlua = vlua}
local M = F
for k, v in pairs(F) do
  M[k:gsub("-", "_")] = v
end
return M
