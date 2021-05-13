if !exists("g:aniseed#env")
  if exists("g:zest#env")
    augroup zestcompile
      autocmd!
      execute "autocmd BufWritePost " . g:zest#env . "/*.fnl :lua require('zest.zest')(vim.fn.expand('%:p'), '" . g:zest#env . "', '/home/sean/.config/nvim/lua/')"
      if exists("g:zest#dev")
        autocmd BufWritePost /home/sean/code/zest/fnl/zest/*.fnl :lua require('zest.zest')(vim.fn.expand('%:p'), '/home/sean/code/zest/fnl/zest', '/home/sean/code/zest/lua/zest')
      end
    augroup end
  end
end

" TODO: remove ending slash from path / if needed
