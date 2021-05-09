local core = {}
core["seq?"] = function(xs)
  local i = 0
  for _ in pairs(xs) do
    i = (i + 1)
    if (nil == xs[i]) then
      return false
    end
  end
  return true
end
core["has?"] = function(xt, y)
  if core["seq?"](xt) then
    for _, v in ipairs(xt) do
      if (v == y) then
        return true
      end
    end
  else
    if (nil ~= xt[y]) then
      return true
    end
  end
  return false
end
return core