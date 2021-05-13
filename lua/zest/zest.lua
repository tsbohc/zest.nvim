local fs = require("zest.fs")
local co = require("zest.core")
local compile = {}
local state = {["initialised?"] = false}
local function get_rtp()
  local r = ""
  local fnl_suffix = "/fnl/?.fnl"
  local lua_suffix = "/lua/?.lua"
  local rtp = (vim.o.runtimepath .. ",")
  for e in rtp:gmatch("(.-),") do
    local f = (e .. "/fnl")
    local l = (e .. "/lua")
    if (1 == vim.fn.isdirectory(f)) then
      r = (r .. ";" .. (e .. fnl_suffix))
    elseif (1 == vim.fn.isdirectory(l)) then
      r = (r .. ";" .. (e .. lua_suffix))
    end
  end
  return r:sub(2)
end
local function init_compiler()
  local fennel = require("zest.fennel")
  if not state["initialised?"] then
    print("<zest> initialise compiler")
    fennel.path = (get_rtp() .. ";" .. fennel.path)
    state["initialised?"] = true
  end
  return fennel
end
compile.compile = function(source, relative_to, target_path)
  if not source:find("macros.fnl$") then
    local fennel = init_compiler()
    local relative = source:gsub(relative_to, "")
    local target = (target_path .. relative:gsub(".fnl$", ".lua"))
    vim.fn.mkdir(fs.dirname(target), "p")
    return fs.write(target, fennel.compileString(fs.read(source)))
  end
end
local function _0_(_, ...)
  return compile.compile(...)
end
setmetatable(compile, {__call = _0_})
return compile