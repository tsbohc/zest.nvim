;; util

(local zest
  ; (zest.foo :bar) => require("zest").foo("bar")
  (setmetatable
    {} {:__index
        (fn [xt key]
          (tset xt key (fn [...] '((. (require :zest) ,key) ,...)))
          (rawget xt key))}))

(fn seq-to-fn [f]
  "allow functions to be passed to binding as statements wrapped in []"
  (if (sequence? f)
    '(fn [] ,(unpack f))
    f))

;; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts {:noremap true
              :expr    false}]
    (each [_ o (ipairs args)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn def-keymap [args lhs rhs]
  (let [(mod opt) (_keymap-options args)]
    (zest.def-keymap mod opt lhs rhs)))

{
 : def-keymap
 }
