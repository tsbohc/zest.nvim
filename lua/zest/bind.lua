local M = {}
local state = {}
_G.___zest = {au = {}, cm = {}, ex = {}, ki = {}, op = {}}
local escapes = {["% "] = "SPACE", ["%!"] = "EXCLAMATION", ["%#"] = "HASH", ["%$"] = "DOLLAR", ["%%"] = "PERCENT", ["%&"] = "AMPERSAND", ["%'"] = "SINGLE_QUOTE", ["%("] = "PARENTHESIS_OPEN", ["%)"] = "PARENTHESIS_CLOSE", ["%*"] = "ASTERISK", ["%+"] = "PLUS", ["%,"] = "COMMA", ["%-"] = "DASH", ["%."] = "PERIOD", ["%/"] = "REVERSE_SLASH", ["%:"] = "COLON", ["%;"] = "SEMICOLON", ["%<"] = "LESS_THAN", ["%="] = "EQUALS", ["%>"] = "GREATER_THAN", ["%?"] = "QUESTION", ["%@"] = "AT_SIGN", ["%["] = "BRACKET_OPEN", ["%\""] = "DOUBLE_QUOTE", ["%\\"] = "SLASH", ["%]"] = "BRACKET_CLOSE", ["%^"] = "CAROT", ["%`"] = "BACKTICK", ["%{"] = "CURLYBRACKET_OPEN", ["%|"] = "BAR_SIGN", ["%}"] = "CURLYBRACKET_CLOSE", ["%~"] = "TILDE"}
local function esc(s)
  local r = s
  for k, v in pairs(escapes) do
    r = r:gsub(k, ("_z_" .. v .. "_z_"))
  end
  return r
end
local function exec_wrapper(kind, id, f, ...)
  local ok_3f, out = pcall(f, ...)
  if not ok_3f then
    return print(("\nzest." .. kind .. "- error while executing '" .. id .. "':\n" .. out))
  else
    return out
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
local function prep_fn(kind, id, f)
  local function _0_(...)
    return exec_wrapper(kind, id, f, ...)
  end
  return _0_
end
local function bind_fn(kind, id, f)
  _G.___zest[kind][esc(id)] = f
  return nil
end
local function get_cmd(kind, id, xt)
  local xt0 = (xt or {})
  local v_lua = ("v:lua.___zest." .. kind .. "." .. esc(id))
  local _0_ = kind
  if (_0_ == "ex") then
    return (v_lua .. "()")
  elseif (_0_ == "ki") then
    return (":call " .. v_lua .. "()<cr>")
  elseif (_0_ == "au") then
    return (":call " .. v_lua .. "()")
  elseif (_0_ == "cm") then
    local _1_
    if xt0.opts then
      _1_ = (xt0.opts .. " ")
    else
      _1_ = ""
    end
    return ("com " .. _1_ .. id .. " :call " .. v_lua .. "(" .. (xt0.args or "") .. ")")
  elseif (_0_ == "op") then
    return (":set operatorfunc=v:lua.___zest.op." .. esc(id) .. "<cr>g@")
  elseif (_0_ == "opl") then
    return (":<c-u>call v:lua.___zest.op." .. esc(id) .. "(v:count1)<cr>")
  elseif (_0_ == "opv") then
    return (":<c-u>call v:lua.___zest.op." .. esc(id) .. "(visualmode())<cr>")
  end
end
local function bind(kind, id, f, xt)
  if check(kind, id, f) then
    local _0_ = type(f)
    if (_0_ == "function") then
      local f0
      local function _1_(...)
        return exec_wrapper(kind, id, f, ...)
      end
      f0 = _1_
      local cmd = get_cmd(kind, id, xt)
      bind_fn(kind, id, f0)
      return cmd
    elseif (_0_ == "string") then
      return f
    end
  end
end
local function count_au()
  local r = 0
  for _, _0 in pairs(_G.___zest.au) do
    r = (1 + r)
  end
  return r
end
M.au = function(events, pattern, ts)
  if not state["au-initialised?"] then
    vim.api.nvim_command("augroup zestautocommands")
    vim.api.nvim_command("autocmd!")
    vim.api.nvim_command("augroup END")
    state["au-initialised?"] = true
  end
  local cmd = bind("au", ("_" .. count_au()), ts)
  local body = ("au " .. events .. " " .. pattern .. " " .. cmd)
  vim.api.nvim_command("augroup zestautocommands")
  vim.api.nvim_command(body)
  return vim.api.nvim_command("augroup END")
end
M.ki = function(modes, fs, ts, opts)
  if check("ki", fs, ts) then
    local kind
    if opts.expr then
      kind = "ex"
    else
      kind = "ki"
    end
    local f = prep_fn(kind, fs, ts)
    for m in string.gmatch(modes, ".") do
      bind_fn(kind, (m .. "_" .. fs), f)
      vim.api.nvim_set_keymap(m, fs, get_cmd(kind, (m .. "_" .. fs)), opts)
    end
    return nil
  end
end
M.cm = function(opts, id, ts, xt)
  local cmd = bind("cm", id, ts, xt)
  return vim.api.nvim_command(cmd)
end
local function def_operator(f, t)
  local r = vim.api.nvim_eval("@@")
  local t0
  if tonumber(t) then
    t0 = "count"
  else
    t0 = t
  end
  print(t0)
  do
    local _1_ = t0
    if (_1_ == "count") then
      vim.api.nvim_command(("norm! " .. ("V" .. vim.v.count1 .. "$y")))
    elseif (_1_ == "line") then
      vim.api.nvim_command(("norm! " .. "`[V`]y"))
    elseif (_1_ == "block") then
      vim.api.nvim_command(("norm! " .. "`[<c-v>`]y"))
    elseif (_1_ == "char") then
      vim.api.nvim_command(("norm! " .. "`[v`]y"))
    else
      local _ = _1_
      vim.api.nvim_command(("norm! " .. ("`<" .. t0 .. "`>y")))
    end
  end
  local context = vim.api.nvim_eval("@@")
  local output = f(context)
  if output then
    vim.fn.setreg("@", output, vim.fn.getregtype("@"))
    vim.api.nvim_command(("norm! " .. "gv\"0p"))
  end
  return vim.fn.setreg("@@", r, vim.fn.getregtype("@@"))
end
M.op = function(fs, ts)
  if check("op", fs, ts) then
    local f
    local function _0_(...)
      return def_operator(ts, ...)
    end
    f = prep_fn("op", fs, _0_)
    bind_fn("op", fs, f)
    vim.api.nvim_set_keymap("n", fs, get_cmd("op", fs), {noremap = true, silent = true})
    vim.api.nvim_set_keymap("n", (fs .. fs), get_cmd("opl", fs), {noremap = true, silent = true})
    return vim.api.nvim_set_keymap("v", fs, get_cmd("opv", fs), {noremap = true, silent = true})
  end
end
return M