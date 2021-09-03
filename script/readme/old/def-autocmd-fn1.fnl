(require-macros :zest.macros)

(def-augroup :restore-position
  (def-autocmd-fn :BufReadPost "*"
    (when (and (> (vim.fn.line "'\"") 1)
               (<= (vim.fn.line "'\"") (vim.fn.line "$")))
      (vim.cmd "normal! g'\""))))

42
