local compile = {}
local state = {["initialised?"] = false}
local fnl_path = "/home/sean/.garden/etc/nvim.d/fnl/"
local lua_path = "/home/sean/.config/nvim/lua/"
local zest_fnl_path = "/home/sean/.local/share/nvim/site/pack/packer/start/zest/fnl/zest/"
local zest_lua_path = "/home/sean/.local/share/nvim/site/pack/packer/start/zest/lua/zest/"
vim.cmd("augroup testgroup")
vim.cmd("autocmd!")
vim.cmd(("autocmd BufWritePost " .. fnl_path .. "*.fnl :lua require('zest.compile')(vim.fn.expand('%:p'), '" .. fnl_path .. "', '" .. lua_path .. "')"))
vim.cmd(("autocmd BufWritePost " .. zest_fnl_path .. "*.fnl :lua require('zest.compile')(vim.fn.expand('%:p'), '" .. zest_fnl_path .. "', '" .. zest_lua_path .. "')"))
vim.cmd("augroup end")
local fs = {}
fs.dirname = function(path)
  return path:match("(.*[/\\])")
end
fs.mkdir = function(path)
  return os.execute(("mkdir -p " .. path))
end
fs.read = function(path)
  local file = assert(io.open(path, "r"))
  local function close_handlers_0_(ok_0_, ...)
    file:close()
    if ok_0_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _0_()
    return file:read("*a")
  end
  return close_handlers_0_(xpcall(_0_, (package.loaded.fennel or debug).traceback))
end
fs.write = function(path, content)
  local file = assert(io.open(path, "w"))
  local function close_handlers_0_(ok_0_, ...)
    file:close()
    if ok_0_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _0_()
    return file:write(content)
  end
  return close_handlers_0_(xpcall(_0_, (package.loaded.fennel or debug).traceback))
end
fs.isdir = function(path)
  local file = io.open(path, "r")
  if (nil == file) then
    return false
  else
    file:close()
    return true
  end
end
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
  if not source:find("macros") then
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