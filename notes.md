wishlist
- keep track of files, remove orphans
- decouple stuff
- exspose this stuff to :, like :se- nocul?
- :Fns to support args
- good logging, like vimpeccable
- normal [jjkk2w]
- full names for everything?

test speed between fennel.compilestring and sh fennel --compile
since fns can be in macro modules, stuff shouldn't pull deps
top level function? (import se-)

(fn warn [message]
  (vim.api.nvim_out_write (.. "zest: " message "\n")))

; name ??
(fn throw [message]
  (error (.. "zest: " message)))
