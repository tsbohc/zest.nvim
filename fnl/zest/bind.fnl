(local M {})

(fn escape [s]
  (s:gsub "[<>]" {:< "\\<" :> "\\>"}))

(local state
  {:ki {}
   :cm {}})

(fn bind! [kind id f]
  "bind function into the state dictionary and return the relevant ex command"
  (let [id-esc (escape id)]
    (tset (. state kind) id-esc f)
    (.. "v:lua.zestExec('" kind "', '" id-esc "')")))

(fn get-cm [kind id t]
  (match t
    :expr (.. "v:lua.zestExec('" kind "', '" (escape id) "')")))

(fn _G.zestExec [kind id-esc ...]
  (let [f (. (. state kind) id-esc)
        id (string.gsub (string.gsub id-esc "\\<" "<") "\\>" ">")
        (ok? result) (pcall f ...)]
    (if (not ok?)
      (error (.. "\n<zest:" kind "> error while executing '" id "':\n" result))
      result)))

(fn M.cm [opts id ts args]
  (match (type ts)
    :function
    (let [cmd (.. "com " opts " " id " :call v:lua.zestExec('cm', '" (escape id) "', " args ")")]
      (bind! :cm id ts)
      (vim.api.nvim_command cmd))
    :string
    ; TODO: decide how to handle args (ignore them?)
    (let [cmd (.. "com " opts " " id " " ts)]
      (vim.api.nvim_command cmd))))

(fn M.ki [modes fs ts opts]
  ; TODO: improve error handling
  (match (type ts)
    :function
    (let [ex (if (. opts :expr) (bind! :ki fs ts) (.. ":call " (bind! :ki fs ts) "<cr>"))]
      (each [m (string.gmatch modes ".")]
        (vim.api.nvim_set_keymap m fs ex opts)))
    :string
    (each [m (string.gmatch modes ".")]
      (vim.api.nvim_set_keymap m fs ts opts))))

M
