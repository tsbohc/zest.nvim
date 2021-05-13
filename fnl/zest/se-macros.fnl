; wishlist
; - keep track of files, remove orphans
; - decouple stuff
; - exspose this stuff to :, like :se- nocul?
; - :Fns to support args
; - good logging, like vimpeccable
; - normal [jjkk2w]
; - full names for everything?

; test speed between fennel.compilestring and sh fennel --compile
; since fns can be in macro modules, stuff shouldn't pull deps
; top level function? (import se-)

(fn warn [message]
  (vim.api.nvim_out_write (.. "zest: " message "\n")))

; name ??
(fn throw [message]
  (error (.. "zest: " message)))

; ---

(fn get-scope [o]
  "get scope for option 'o'"
  (let [(okay? info) (pcall vim.api.nvim_get_option_info o)]
    (when okay?
      (. info :scope))))

(fn set-option [o v s]
  "set option 'o' to value 'v' in scope 's'"
  (match s
    :global `(vim.api.nvim_set_option       ,o ,v)
    :win    `(vim.api.nvim_win_set_option 0 ,o ,v)
    :buf    `(vim.api.nvim_buf_set_option 0 ,o ,v)
    _       (warn (.. "se- invalid scope '" s "' for option '" o "'"))))

(fn se- [o v]
  "set option sym 'o' to value 'v'"
  (let [o (if (= :string (type o)) o `,(tostring o))
        v (if (= nil v) true v)
        s (get-scope o)]
    (if s
      `,(set-option o v s)
      (= "no" (o:sub 1 2))
      (se- (o:sub 3) false)
      (warn (.. "se- option '" o "' not found")))))

(fn colo- [v]
  `(vim.cmd ,(.. "colo " (tostring v))))

{: se-
 : colo-}
