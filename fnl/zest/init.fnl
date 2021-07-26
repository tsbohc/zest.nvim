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
  (let [conf {:verbose-compiler true
              :disable-compiler false}]
    (when xt
      (each [k v (pairs xt)]
        (tset conf k v)))
    conf))

(fn M.setup [xt]
  (set _G._zest
       {:keymap {}
        :autocmd {:# 1}
        :textobject {}
        :operator {}
        :v {:# 1}
        :config (config xt)}))

M
