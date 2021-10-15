;; util

(local runtime
  ; (runtime.foo :bar) => require("runtime").foo("bar")
  (setmetatable
    {} {:__index
        (fn [xt key]
          (tset xt key (fn [...] '((. (require :lime) ,key) ,...)))
          (rawget xt key)
          )}))

(fn seq-to-fn [f]
  "allow functions to be passed to binding as statements wrapped in []"
  (if (sequence? f)
    '(fn [] ,(unpack f))
    f))

;; vlua

(fn vlua [f]
  (runtime.vlua f))

(fn vlua-format [s f]
  (runtime.vlua-format s f))

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
    (runtime.def-keymap mod opt lhs rhs)))

;; autocmd

(fn def-autocmd [eve pat rhs]
  (runtime.def-autocmd eve pat rhs))

(fn def-augroup [name ...]
  '((. (require :lime) :def-augroup) ,name (fn [] ,...)))

;; set options

(fn _set-option [scope action key val]
  "complete vim.opt wrapper"
  (let [opt (.. "vim.opt" scope "." key)]
    (if action
      '(,(sym (.. opt ":" action)) ,val)
      '(set ,(sym opt) ,val))))

(fn set-option [x y z]
  "prepare arguments for _set-option"
  (match [x y z]
    [x y nil] (_set-option "" nil (tostring x) (if (= nil y) true y))
    [x y   z] (let [(scope action) (match (tostring (. x 1))
                                     :l (values "_local"  (. x 2))
                                     :g (values "_global" (. x 2))
                                     _  (values ""        (. x 1)))]
                (_set-option scope action (tostring y) (if (= nil z) true z)))))

{
 : vlua
 : vlua-format
 : set-option
 : def-keymap
 : def-autocmd
 : def-augroup
 }
