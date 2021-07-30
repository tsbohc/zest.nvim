(local M {})

(fn decode [bytes]
  (var s "")
  (each [b (bytes:gmatch "([^_]+)")]
    (set s (.. s (string.char b))))
  s)

(fn encode [s]
  (.. "_" (string.gsub s "." (fn [c] (.. (string.byte c) "_")))))

(fn wrap [kind id f]
  (let [(ok? out) (pcall f)]
    (if (not ok?)
      (let [f (require :zest.fennel)]
        (print (.. "\nzest: error while executing " kind " '" (decode id) "':\n" out)))
      out)))

(fn new-xt [kind]
  (setmetatable
    {:#kind kind}
    {:__newindex
     (fn [xt k v]
       ;(rawset xt k (fn [] (wrap (. xt "#kind") k v)))
       (rawset xt k v))}))

(fn store [f kind id]
  (if id
    (let [id (encode id)]
      (tset _G._zest kind id (fn [] (wrap kind id f)))
      (.. "v:lua._zest." kind "." id))
    ;(let [n (. _G._zest kind :#)]
    ;  (tset _G._zest kind n (fn [] (wrap kind n f))))
    ))

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
        :command {}
        :autocmd {:# 1}
        :textobject {}
        :operator {}
        :v {:# 1}
        :config (config xt)
        ;:store store
        }))

M
