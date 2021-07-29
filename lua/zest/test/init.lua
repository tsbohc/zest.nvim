local M = {}
M["="] = function(x, y, description)
  if (x == y) then
    return print(("  + " .. description))
  else
    return print((">>>>>>>>>>>>>>> YOU SUCK! " .. description .. "\n" .. "    " .. vim.inspect(x) .. " != " .. vim.inspect(y)))
  end
end
M["?"] = function(x, description)
  if x then
    return print(("  + " .. description))
  else
    return print((">>>>>>>>>>>>>>> YOU SUCK! " .. description .. "\n" .. "    " .. vim.inspect(x)))
  end
end
return M
