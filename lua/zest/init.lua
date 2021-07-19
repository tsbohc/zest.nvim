local M = {}
M.setup = function()
  _G["ZEST"] = (_G.ZEST or {autocmd = {}, keymap = {}})
  return nil
end
return M
