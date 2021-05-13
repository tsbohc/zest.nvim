(local M {})

; NOTE: vim complained about eof when building a command for __ki_execute_map with '<C-M>'

(local ki {})

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

(fn _G.__ki_execute_map [id]
  ;(print (reverse-strip id))
  (let [f (. ki id)
        (ok? result) (pcall f)]
    (if (not ok?)
      (error (.. "\n[ ki- ]: error while executing mapping '" (reverse-strip id) "':\n" result))
      result)))

(fn bind [modes fs ts opts]
  ;(print fs ts)
  (if (not= nil fs)
    (match (type ts)
      :function
      (let [id (strip fs)
            cmd (if (. opts :expr)
                  (.. "v:lua.__ki_execute_map('" id "')")
                  (.. ":lua _G.__ki_execute_map('" id "')<cr>"))]
        (tset ki id ts)
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
  M {:__call (fn [_ ...] (bind ...))})

M
