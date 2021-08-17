do
  -- "zest.def-autocmd-string"
  local zest_mod_1_ = "nv"
  local zest_opt_2_ = {expr = false, noremap = true}
  local zest_lhs_3_ = "H"
  local zest_rhs_4_ = "0"
  for m_40_auto in string.gmatch(zest_mod_1_, ".") do
    vim.api.nvim_set_keymap(m_40_auto, zest_lhs_3_, zest_rhs_4_, zest_opt_2_)
  end
end
return 42
