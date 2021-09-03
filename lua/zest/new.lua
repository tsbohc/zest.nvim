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
      elseif ((type(_1_) == "table") and ((type((_1_).opt) == "table") and (((_1_).opt).expr == false)) and ((_1_).kind == "keymap")) then
        vlua0 = (":call " .. vlua .. "()<cr>")
      elseif ((type(_1_) == "table") and ((_1_).kind == "autocmd")) then
        vlua0 = (":call " .. vlua .. "()")
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
local function def_keymap(mod, opt, lhs, rhs)
  local data = bind({kind = "keymap", lhs = lhs, mod = mod, opt = opt, rhs = rhs})
  for m in (data.mod):gmatch(".") do
    vim.api.nvim_set_keymap(m, data.lhs, data.rhs, data.opt)
  end
  return nil
end
local F = {["def-autocmd"] = __fnl_global__def_2dautocmd, ["def-keymap"] = def_keymap, bind = bind}
local M = F
for k, v in pairs(F) do
  M[k:gsub("-", "_")] = v
end
return M
