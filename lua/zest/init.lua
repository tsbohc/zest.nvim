local M = {}
M.setup = function()
  _G["_zest"] = (_G.ZEST or {autocmd = {}, keymap = {}, statusline = {}, v = {__count = 1}})
  return nil
end
return M
