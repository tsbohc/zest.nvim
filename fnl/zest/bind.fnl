(local M {})

; NOTE: vim complained about eof when building a command for zest_exec with '<C-M>'
; prooobably due to <...> being special

(fn strip [s]
  (s:gsub "[<>-]"
          {"<" "_left_angle_bracket_"
           ">" "_right_angle_bracket_"
           "-" "_dash_"}))

(fn reverse-strip [s]
  (-> s
      (string.gsub "_left_angle_bracket_" "<")
      (string.gsub "_right_angle_bracket_" ">")
      (string.gsub "_dash_" "-")))

(local state
  {:ki {}
   :cm {}})

(fn M.bind [kind id f]
  "bind a function into the state dictionary"
  (tset (. state kind) id f))

;(fn excmd [kind id v?]
;  (if v?
;    (.. "v:lua.zestExec('" kind "', '" id "')")
;    (.. ":lua _G.zestExec('" kind "', '" id "')")))

(fn _G.zestExec [kind id ...]
  (let [f (. (. state kind) id)
        (ok? result) (pcall f ...)]
    (if (not ok?)
      (error (.. "\n<zest:" kind "> error while executing '" (reverse-strip id) "':\n" result))
      result)))

(fn M.create-cmd [name]
  (vim.api.nvim_command (.. "com! " name " :lua _G.zestExec(\"cm\", \"" name "\")")))

(fn M.create-map [modes fs ts opts]
  ;(print fs ts)
  (if (not= nil fs)
    (match (type ts)
      :function
      (let [id (strip fs)
            cmd (if (. opts :expr)
                  (.. "v:lua.zestExec('ki', '" id "')")
                  (.. ":lua _G.zestExec('ki', '" id "')<cr>"))]
        (M.bind :ki id ts)
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
