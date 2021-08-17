(require-macros :zest.macros)

(def-keymap-fn :k [nv :expr]
  (if (> vim.v.count 0) "k" "gk"))

42
