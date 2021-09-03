(require-macros :zest.macros)

(def-autocmd [:BufNewFile my_event] [:*.html :*.xml]
  "setlocal nowrap")

42
