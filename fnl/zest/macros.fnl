; TODO:
; debug mode
; au- create autocommand
; cm- bind function as excmd, def-cm- create function as excmd? maybe even defmap? (def-ki- <c-m> [nvo :expr] (if ... :a)
; ki- fns not silenced by default, investigate

; NB!
; attempts to optimize requiring bind once (into a local, global, etc) with 100+ rules showed no noticible improvementm and even slowdowns, 5ms on average

; util

(fn xs-str [xs]
  "convert seq of symbols 'xs' to a seq of strings"
  (let [r []]
    (for [i 1 (# xs)]
      (table.insert r `,(tostring (. xs i))))
    r))

; se-

(fn se- [key val]
  "set option 'key' to value 'val'"
  (let [key (tostring key)
        val (if (= nil val) true val)
        (ok? scope) (pcall (fn [] (. (vim.api.nvim_get_option_info key) :scope)))]
    (if ok?
      (match scope
        :global `(vim.api.nvim_set_option       ,key ,val)
        :win    `(vim.api.nvim_win_set_option 0 ,key ,val)
        :buf    `(vim.api.nvim_buf_set_option 0 ,key ,val)
        _ (print (.. "<zest:se> invalid scope '" scope "' for option '" key "'")))
      (if (= :no (key:sub 1 2))
            (se- (key:sub 3) false)
            (print (.. "<zest:se> invalid option '" key "'"))))))

; opt-

(fn opt-get [key]
  ; since :get errors out on unset options, here's an ugly thing
  (let [key (tostring key)]
    `(let [(ok?# val#) (pcall (fn [] (: (. vim.opt ,key) :get)))]
       (if ok?# val# nil))))

(fn so- [key val]
  (let [key (tostring key)
        val (if (= nil val) true val)
        dec (key:sub -1)
        clean-key (key:sub 1 -2)
        opt `(. vim.opt ,clean-key)]
    (match dec
      "?" `(opt-get ,clean-key)
      "!" `(tset vim.opt ,clean-key (not (opt-get ,clean-key)))
      "+" `(: ,opt :append  ,val)
      "-" `(: ,opt :remove  ,val)
      "^" `(: ,opt :prepend ,val)
      _   `(tset vim.opt ,key ,val))))

; li- & ki-

(fn keymap-options [args]
  "convert seq of options 'args' to modes string and keymap option dict"
  (let [modes (tostring (table.remove args 1))
        opts-xs (xs-str args)
        opts {:noremap true}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn ki- [args fs ts]
  "bind 'fs' to 'ts' by reference via runtime evaluation"
  (let [(modes opts) (keymap-options args)]
    `((. (require :zest.bind) :ki) ,modes ,fs ,ts ,opts)))

(fn li- [args fs ts]
  "bind 'fs' to 'ts' as literals via compile time parsing"
  (let [(modes opts) (keymap-options args)
        fs (tostring fs)
        ts (tostring ts)
        out []]
    (each [m (string.gmatch modes ".")]
      (table.insert out `(vim.api.nvim_set_keymap ,m ,fs ,ts ,opts)))
    (if (> (# out) 1)
      `(do ,(unpack out))
      `,(unpack out))))

; te-

(fn te- [fs ts]
  `((. (require :zest.bind) :te) ,fs ,ts))

; op-

(fn op- [fs ts]
  `((. (require :zest.bind) :op) ,fs ,ts))

; au-

(fn au- [events pattern ts]
  (let [events (table.concat (xs-str events) ",")]
    `((. (require :zest.bind) :au) ,events ,pattern ,ts)))

; cm-

(fn cm- [...]
  ; TODO: redo this, this is dumb
  ; FIXME: there could be a use case where name should be composable
  (match (# [...])
    4 (let [(opts name f args) ...
            opts (table.concat (xs-str opts) " ")
            args (table.concat (xs-str args) " ")]
        `((. (require :zest.bind) :cm) ,opts ,(tostring name) ,f ,args))
    3 (let [(opts name str) ...
            opts (table.concat (xs-str opts) " ")
            args ""]
        `((. (require :zest.bind) :cm) ,opts ,(tostring name) ,str))
    2 (let [(name f) ...
            opts ""
            args ""]
        `((. (require :zest.bind) :cm) ,opts ,(tostring name) ,f ,args))))

; pa-

(fn pa- [repo ...]
  (let [formatted [(tostring repo)]
        args [...]
        out []]
    (each [i v (ipairs args)]
      (when (and (not= 1 i) (= 0 (% (# args) 2)))
        (let [k (. args (- i 1))]
          (if (not= k :zest)
            (tset formatted k v)
            (table.insert out `(,v))))))
    (table.insert out `(use ,formatted))
    (if (> (# out) 1)
      `(do ,(unpack out))
      `,(unpack out))))

; misc

(fn exec- [s]
  "execute string 's' with nvim_command"
  `(vim.api.nvim_command ,s))

(fn norm- [s]
  "execute string 's' as normal mode commands"
  `(vim.api.nvim_command (.. "norm! " ,s)))

(fn eval- [s]
  "evaluate string 's' with nvim_eval"
  `(vim.api.nvim_eval ,s))

(fn viml- [s]
  "execute string 's' with nvim_exec"
  `(vim.api.nvim_exec ,s true))

(fn colo- [v]
  "set colorscheme to 'v'"
  `(vim.api.nvim_exec ,(.. "colo " v) true))

(fn lead- [v]
  "map leader to 'v'"
  `(tset vim.g :mapleader ,v))

(fn g- [k v]
  "set 'k' to 'v' on vim.g table"
  `(tset vim.g ,(tostring k) ,v))

{: so-
 : opt-get
 : se-
 : li-
 : ki-
 : te-
 : op-
 : au-
 : cm-
 : pa-
 : exec-
 : norm-
 : eval-
 : viml-
 : colo-
 : lead-
 : g-}
