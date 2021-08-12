local fs = {}
fs.read = function(path)
  local file = assert(io.open(path, "r"))
  local function close_handlers_7_auto(ok_8_auto, ...)
    file:close()
    if ok_8_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _2_()
    return file:read("*a")
  end
  return close_handlers_7_auto(xpcall(_2_, (package.loaded.fennel or debug).traceback))
end
fs.write = function(path, content)
  local file = assert(io.open(path, "w"))
  local function close_handlers_7_auto(ok_8_auto, ...)
    file:close()
    if ok_8_auto then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _4_()
    return file:write(content)
  end
  return close_handlers_7_auto(xpcall(_4_, (package.loaded.fennel or debug).traceback))
end
fs.dirname = function(path)
  return path:match("(.*[/\\])")
end
local state = {fennel = false}
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
local function load_fennel()
  local fennel = require("zest.fennel")
  fennel.path = (get_rtp() .. ";" .. fennel.path)
  state.fennel = fennel
  vim.api.nvim_command(":redraw")
  vim.api.nvim_echo({{" zest ", "Search"}, {" ", "None"}, {"initialise compiler", "None"}}, false, {})
  return state.fennel
end
local M = {}
M.compile = function()
  local source = vim.fn.expand("%:p")
  if not source:find("macros.fnl$") then
    local fennel = (state.fennel or load_fennel())
    local fnl_path = vim.fn.resolve(_G._zest.config.source)
    local lua_path = vim.fn.resolve(_G._zest.config.target)
    local target = string.gsub(string.gsub(source, ".fnl$", ".lua"), fnl_path, lua_path)
    if _G._zest.config["verbose-compiler"] then
      vim.api.nvim_command(":redraw")
      vim.api.nvim_echo({{" zest ", "Search"}, {" ", "None"}, {vim.fn.expand("%:t"), "None"}, {" => ", "Comment"}, {target:gsub(vim.env.HOME, "~"), "None"}}, false, {})
    end
    local _7_ = {fnl_path, lua_path}
    if ((type(_7_) == "table") and (nil ~= (_7_)[1]) and (nil ~= (_7_)[2])) then
      local x = (_7_)[1]
      local y = (_7_)[2]
      vim.fn.mkdir(fs.dirname(target), "p")
      return fs.write(target, fennel.compileString(fs.read(source)))
    elseif ((type(_7_) == "table") and ((_7_)[1] == nil) and (nil ~= (_7_)[2])) then
      local x = (_7_)[2]
      return print("<zest> invalid source path!")
    elseif ((type(_7_) == "table") and (nil ~= (_7_)[1]) and ((_7_)[2] == nil)) then
      local x = (_7_)[1]
      return print("<zest> invalid target path!")
    end
  end
end
local function _10_(_, ...)
  return M.compile(...)
end
setmetatable(M, {__call = _10_})
return M
