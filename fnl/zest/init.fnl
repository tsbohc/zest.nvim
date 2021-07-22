(local M {})

(fn decode [bytes]
  (var s "")
  (each [b (bytes:gmatch "([^_]+)")]
    (set s (.. s (string.char b))))
  s)

(fn wrap [kind id f]
  (let [(ok? out) (pcall f)]
    (if (not ok?)
      (print (.. "\nzest: error while executing " kind " '" (decode id) "':\n" out))
      out)))

(fn new-xt [kind]
  (setmetatable
    {:#kind kind}
    {:__newindex
     (fn [xt k v]
       ;(rawset xt k (fn [] (wrap (. xt "#kind") k v)))
       (rawset xt k v))}))

(fn config [xt]
  (let [conf {:source (vim.fn.resolve (.. (vim.fn.stdpath :config) "/fnl"))
              :target (vim.fn.resolve (.. (vim.fn.stdpath :config) "/lua"))
              :verbose-compiler true
              :disable-compiler false}]
    (when xt
      (each [k v (pairs xt)]
        (tset conf k v)))
    conf))

(fn M.setup [xt]
  ;(print (.. "config:\n" (vim.inspect config)))
  (set _G._zest
       {:keymap {:# 1} ; depr
        :statusline {:# 1}
        :autocmd {:# 1}
        :keymap (new-xt :keymap)
        :v {:# 1}
        :config (config xt)}))

M
