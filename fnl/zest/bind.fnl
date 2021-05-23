(local M {})
(local state {})

(require-macros :zest.macros)

; TODO
; store commands applied to functions in state too

; FIXME
; binding to percent sign is potentially broken for some reason

; we're storing them in _G for operator-func compatibility of the wrapper
(set _G.___zest {:ex {} :ki {} :au {} :cm {} :op {}})

; {{{
; v:lua doesn't support ["id"] syntax, so... yeah
(local escapes
  {"%<" "LESS_THAN"
   "%>" "GREATER_THAN"
   "%`" "BACKTICK"
   "%!" "EXCLAMATION"
   "%@" "AT_SIGN"
   "%#" "HASH"
   "%$" "DOLLAR"
   "%%" "PERCENT"
   "%^" "CAROT"
   "%&" "AMPERSAND"
   "%*" "ASTERISK"
   "%(" "PARENTHESIS_OPEN"
   "%)" "PARENTHESIS_CLOSE"
   "%[" "BRACKET_OPEN"
   "%]" "BRACKET_CLOSE"
   "%{" "CURLYBRACKET_OPEN"
   "%}" "CURLYBRACKET_CLOSE"
   "%-" "DASH"
   "%+" "PLUS"
   "%=" "EQUALS"
   "%~" "TILDE"
   "% " "SPACE"
   "%:" "COLON"
   "%;" "SEMICOLON"
   "%'" "SINGLE_QUOTE"
   "%\"" "DOUBLE_QUOTE"
   })
; }}}

(fn esc [s]
  (var r s) (each [k v (pairs escapes)] (set r (r:gsub k (.. "___" v "___")))) r)

(fn exec-wrapper [kind id f ...]
  (let [(ok? out) (pcall f ...)]
    (if (not ok?)
      (print (.. "\nzest." kind "- error while executing '" id "':\n" out))
      out)))

(fn check [kind fs ts]
  "handle nil errors during binding"
  (match [fs ts]
    [nil nil] (print (.. "zest." kind "- both sides of a binding evaluated to nil!"))
    [ x  nil] (print (.. "zest." kind "- attempt to bind nil to '" (tostring fs) "'!"))
    [nil  y ] (print (.. "zest." kind "- attempt to bind '" (tostring ts) "' to nil!"))
    _ true))

(fn prep-fn [kind id f]
  (partial exec-wrapper kind id f))

(fn bind-fn [kind id f]
  (tset _G.___zest kind (esc id) f))

(fn get-cmd [kind id xt]
  (let [xt (or xt {})
        v-lua (.. "v:lua.___zest." kind "." (esc id))]
    (match kind
      :ex  (.. v-lua "()")
      :ki  (.. ":call " v-lua "()<cr>")
      :au  (.. ":call " v-lua "()")
      :cm  (.. "com " (if xt.opts (.. xt.opts " ") "") id " :call " v-lua "(" (or xt.args "") ")")
      :opn (.. ":set operatorfunc=v:lua.___zest.op." (esc id) "<cr>g@")
      :opv (.. ":<c-u>call v:lua.___zest.op." (esc id) "(visualmode())<cr>"))))

(fn bind [kind id f xt]
  (if (check kind id f)
    (match (type f)
      :function
      (let [f (partial exec-wrapper kind id f)
            cmd (get-cmd kind id xt)]
        (bind-fn kind id f)
        cmd)
      :string f)))

(fn count-au []
  (var r 0)
  (each [_ _ (pairs _G.___zest.au)]
    (set r (+ 1 r)))
  r)

(fn M.au [events pattern ts]
  (when (not state.au-initialised?)
    (vim.api.nvim_command "augroup zestautocommands")
    (vim.api.nvim_command "autocmd!")
    (vim.api.nvim_command "augroup END")
    (set state.au-initialised? true))
  (let [cmd (bind :au (.. "_" (count-au)) ts)
        body (.. "au " events " " pattern " " cmd)]
    (vim.api.nvim_command "augroup zestautocommands")
    (vim.api.nvim_command body)
    (vim.api.nvim_command "augroup END")))

; TODO preprocess modes into a seq
; we need to store the fn per mode so that a different functins may be bound to the same fs in other modes
(fn M.ki [modes fs ts opts]
  "define keybinds"
  (if (check :ki fs ts)
    (let [kind (if opts.expr :ex :ki)
          f (prep-fn kind fs ts)]
      (each [m (string.gmatch modes ".")]
        (bind-fn kind (.. m "_" fs) f)
        (vim.api.nvim_set_keymap m fs (get-cmd kind (.. m "_" fs)) opts)))))

(fn M.cm [opts id ts xt]
  "define ex commands"
  (let [cmd (bind :cm id ts xt)]
    (vim.api.nvim_command cmd)))

(fn def-operator [f t]
  (let [r (eval- "@@")]
    (match t
      :char (norm- "`[v`]y")
      _     (norm- (.. "`<" t "`>y")))
    (let [context (eval- "@@")
          output (f context)]
      (when output
        (vim.fn.setreg "@" output (vim.fn.getregtype "@"))
        (norm- "gv\"0p"))
      (vim.fn.setreg "@@" r (vim.fn.getregtype "@@")))))

(fn M.op [fs ts]
  (if (check :op fs ts)
    (let [f (prep-fn :op fs (partial def-operator ts))]
      (bind-fn :op fs f)
      (vim.api.nvim_set_keymap "n" fs (get-cmd :opn fs) {:noremap true :silent true})
      (vim.api.nvim_set_keymap "v" fs (get-cmd :opv fs) {:noremap true :silent true}))))

M
