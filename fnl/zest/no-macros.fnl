(fn x-str [x]
  "convert symbol 'xs' to a string"
  `,(tostring x))

(fn no- [cmd]
  "execute passed 'cmd' as normal mode commands"
  (let [s (x-str cmd)]
    `(vim.api.nvim_command ,(.. "norm! " s))))

{: no-}
