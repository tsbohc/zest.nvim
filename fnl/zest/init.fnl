(fn config [xt]
  (let [conf {:verbose-compiler true
              :disable-compiler false}]
    (when xt
      (each [k v (pairs xt)]
        (tset conf k v)))
    conf))

(fn setup [xt]
  (set _G._zest
       {:keymap {:# 1}
        :command {:# 1}
        :autocmd {:# 1}
        :v {:# 1}
        :config (config xt)}))

{: setup}
