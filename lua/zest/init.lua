local fs = require("zest.fs")
local co = require("zest.core")
local compile = {}
local state = {["initialised?"] = false}
local fnl_path = "/home/sean/.garden/etc/nvim.d/fnl/"
local lua_path = "/home/sean/.config/nvim/lua/"
local zest_fnl_path = "/home/sean/code/zest/fnl/zest/"
local zest_lua_path = "/home/sean/code/zest/lua/zest/"
vim.cmd("augroup testgroup")
vim.cmd("autocmd!")
vim.cmd(("autocmd BufWritePost " .. fnl_path .. "*.fnl :lua require('zest')(vim.fn.expand('%:p'), '" .. fnl_path .. "', '" .. lua_path .. "')"))
vim.cmd(("autocmd BufWritePost " .. zest_fnl_path .. "*.fnl :lua require('zest')(vim.fn.expand('%:p'), '" .. zest_fnl_path .. "', '" .. zest_lua_path .. "')"))
vim.cmd("augroup end")
local function get_rtp()
  local r = ""
  local fnl_suffix = "/fnl/?.fnl"
  local lua_suffix = "/lua/?.lua"
  local rtp = (vim.o.runtimepath .. ",")
  for e in rtp:gmatch("(.-),") do
    local f = (e .. "/fnl")
    local l = (e .. "/lua")
    if fs.isdir(f) then
      r = (r .. ";" .. (e .. fnl_suffix))
    elseif fs.isdir(l) then
      r = (r .. ";" .. (e .. lua_suffix))
    end
  end
  return r:sub(2)
end
local function init_compiler()
  local fennel = require("zest.fennel")
  if not state["initialised?"] then
    print("zest: initiate compiler")
    fennel.path = (get_rtp() .. ";" .. fennel.path)
    state["initialised?"] = true
  end
  return fennel
end
compile.compile = function(source, relative_to, target_path)
  local except = {"se-", "ki-"}
  if not co["has?"](except, source:sub(-7, -5)) then
    local fennel = init_compiler()
    local relative = source:gsub(relative_to, "")
    local target = (target_path .. relative:gsub(".fnl$", ".lua"))
    fs.mkdir(fs.dirname(target))
    return fs.write(target, fennel.compileString(fs.read(source)))
  end
end
local function _0_(_, ...)
  return compile.compile(...)
end
setmetatable(compile, {__call = _0_})
return compile