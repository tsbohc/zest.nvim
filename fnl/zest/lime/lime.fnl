(local M {})

(set _G.zest {:keymap {} :user {}})

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

(fn _vlua [kind f]
  (let [id (M.id)]
    (tset _G.zest kind id f)
    (.. "v:lua.zest." kind "." id)))

(fn M.vlua [f]
  (_vlua :user f))

(fn M.keymap_id [lhs modes]
  (.. "k1"
      (string.gsub lhs "%W" (fn [c] (string.byte c)))
      "m0"
      modes))

(fn M.keymap_vlua [id opts]
  (if opts.expr
    (.. "v:lua.zest.keymap." id ".f()")
    (.. ":call v:lua.zest.keymap." id ".f()<cr>")))

M
