local fs = {}
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
fs.dirname = function(path)
  return path:match("(.*[/\\])")
end
fs.mkdir = function(path)
  return os.execute(("mkdir -p " .. path))
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
return fs
