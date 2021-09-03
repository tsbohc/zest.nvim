(require-macros :zest.macros)

(each [_ k (ipairs [:h :j :k :l])]
  (def-keymap (.. "<c-" k ">") [n] (.. "<c-w>" k)))

42
