if !exists("g:aniseed#env")
    augroup zestcompile
        autocmd!
        execute "autocmd BufWritePost " . resolve(stdpath("config") . "/fnl/*.fnl") . " :lua require('zest')(vim.fn.expand('%:p'), '" . resolve(stdpath("config") . "/fnl") . "', '" . stdpath("config") . "/lua')"
        autocmd BufWritePost /home/sean/code/zest/fnl/zest/*.fnl :lua require('zest')(vim.fn.expand('%:p'), '/home/sean/code/zest/fnl/zest', '/home/sean/code/zest/lua/zest')
    augroup end
end
