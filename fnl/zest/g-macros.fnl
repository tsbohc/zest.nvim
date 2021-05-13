(fn x-str [x]
  "convert symbol 'xs' to a string"
  `,(tostring x))

(fn g- [k v]
  (let [k (x-str k)]
    `(tset vim.g ,k ,v)))

{: g-}


