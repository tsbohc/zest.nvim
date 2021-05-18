(local M {})

; NOTE: vim complained about eof when building a command for zest_exec with '<C-M>'
; prooobably due to <...> being special

(fn escape [s]
  (s:gsub "[<>]" {:< "\\<" :> "\\>"}))

(local state
  {:ki {}
   :cm {}})

(fn bind! [kind id f]
  "bind function into the state dictionary"
  (let [id-esc (escape id)]
    (tset (. state kind) id-esc f)
    (.. "v:lua.zestExec('" kind "', '" id-esc "')")))

(fn _G.zestExec [kind id-esc ...]
  (let [f (. (. state kind) id-esc)
        id (string.gsub (string.gsub id-esc "\\<" "<") "\\>" ">")
        (ok? result) (pcall f ...)]
    (if (not ok?)
      (error (.. "\n<zest:" kind "> error while executing '" id "':\n" result))
      result)))

(fn M.cm [id f]
  (vim.api.nvim_command (.. "com! " id " :call " (bind! :cm id f))))

(fn M.ki [modes fs ts opts]
  (match (type ts)
    :function
    (let [ex (if (. opts :expr) (bind! :ki fs ts) (.. ":call " (bind! :ki fs ts) "<cr>"))]
      (each [m (string.gmatch modes ".")]
        (vim.api.nvim_set_keymap m fs ex opts)))))

(fn M.create-map [modes fs ts opts]
  (if (not= nil fs)
    (match (type ts)
      :function
      (let [cmd (if (. opts :expr)
                  (bind! :ki fs ts)
                  (.. ":call " (bind! :ki fs ts) "<cr>"))]
        (each [m (string.gmatch modes ".")]
          (vim.api.nvim_set_keymap m fs cmd opts)))
      :string
      (let [cmd ts]
        (each [m (string.gmatch modes ".")]
          (vim.api.nvim_set_keymap m fs cmd opts)))
      _ (print (.. "<zest:ki> unhandled type '" (type ts) "' of right side in binding '" fs "'")))
    (if (not= nil ts)
      (print (.. "<zest:ki> left side of a binding evaluated to nil!"))
      (print (.. "<zest:ki> both sides of a binding evaluated to nil!")))))

(setmetatable
  M {:__call (fn [_ ...] (M.create-map ...))})

M
