(local M {})

(set _G.zest {:# 1 :keymap {} :user {} :autocmd {}})

(var n 1)

(fn M.concat [xs d]
  (let [d (or d "")]
    (if
      (= (type xs) :string)
      xs
      (= (type xs) :number)
      (tostring xs)
      (table.concat xs d))))

(fn M.id []
  (let [id (.. "_" n)]
    (set n (+ n 1))
    id))

(fn M.keymap_id [lhs modes]
  (.. "_"
      (string.gsub lhs "%W" (fn [c] (string.byte c)))
      "_"
      modes))

(fn M.keymap_vlua [id opts]
  (if opts.expr
    (.. "v:lua.zest.keymap." id "()")
    (.. ":call v:lua.zest.keymap." id "()<cr>")))

; i need entr fired up

M
