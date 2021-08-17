(require-macros :zest.macros)

(vim.cmd
  (vlua-format
    ":com -nargs=* Mycmd :call %s(<f-args>)"
    (fn [...]
      (print ...))))

42
