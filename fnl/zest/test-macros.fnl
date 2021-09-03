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

(fn call [name ...]
  '((. (require :zest) ,name) ,...))

(fn seq-to-fn [f]
  (if (sequence? f)
    '(fn [] ,(unpack f))
    f))

(fn def-keymap [args lhs rhs]
  (let [(mod opt) (_keymap-options args)]
    (if rhs
      (call :def-keymap       mod opt lhs (seq-to-fn rhs))
      (call :def-keymap-pairs mod opt lhs))))

(fn def-autocmd [eve pat rhs]
  (call :def-autocmd eve pat (seq-to-fn rhs)))

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [definition (.. "augroup " name)]
    (list 'do
          (list 'vim.cmd definition)
          (when (not dirty?)
            (list 'vim.cmd "autocmd!"))
          (when (> (length [...]) 0)
            (list 'do ...))
          (list 'vim.cmd "augroup END"))))

(fn def-augroup [name ...]
  (_create-augroup false name ...))

(fn def-augroup-dirty [name ...]
  (_create-augroup true name ...))

;; options

(fn _set-option [scope action key val]
  "complete vim.opt wrapper"
  (let [opt (.. "vim.opt" scope "." key)]
    (if action
      (list (sym (.. opt ":" action)) val)
      (list 'set (sym opt) val))))

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
 : def-keymap

 : def-augroup
 : def-augroup-dirty

 : def-autocmd
 : set-option
 }
