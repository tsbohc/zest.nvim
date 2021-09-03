(require-macros :zest.lime.macros)
(local lime (require :zest.lime))

; def-test

; {{{
(fn clear [] (lime.setup))

(clear)

(set _G.zest_tests {})

(macro def-test [name ...]
  `(tset _G :zest_tests ,(tostring name) (fn ,name [] ,...)))

(local t {})

(fn t.= [x y description]
  (if (= x y)
    (print (.. " + " description))
    (print (.. "  YOU SUCK! " description "\n" "    " (vim.inspect x) " != " (vim.inspect y)))))

(fn t.? [x description]
  (if x
    (print (.. " + " description))
    (print (.. "  YOU SUCK! " description "\n" "    " (vim.inspect x)))))


; keymaps

(fn rinput [keys]
  (print "\n")
  (let [raw-keys (vim.api.nvim_replace_termcodes keys true false true)]
    (vim.api.nvim_feedkeys raw-keys "mx" false)))

(fn t.k [description]
  (rinput "<F4>")
  (t.? vim.g.zest_received description)
  (tset vim.g :zest_received false)
  (clear))

(fn t.a [description]
  (vim.cmd "doautocmd User ZestEvent")
  (t.? vim.g.zest_received description)
  (tset vim.g :zest_received false)
  (clear))
; }}}

; tests

(def-test _def-keymap
  (local KEY "<F4>")
  (local CMD ":lua vim.g.zest_received = true<cr>")

  (def-keymap [n :silent] "<F4>" ":lua vim.g.zest_received = true<cr>")
  (t.k "strings")

  (let [cmd CMD]
    (def-keymap [n :silent] KEY cmd))
  (t.k "lowercase")

  (def-keymap [n :silent] KEY (fn [] (set vim.g.zest_received true)))
  (t.k "normal fn")

  (def-keymap [n :silent] KEY #(set vim.g.zest_received true))
  (t.k "hash fn")

  (def-keymap [n :silent] KEY (partial (fn [x] (set vim.g.zest_received x)) true))
  (t.k "partial fn")

  (def-keymap [n :silent] KEY [(set vim.g.zest_received true)])
  (t.k "sequence fn")

  (fn Testfn [] (set vim.g.zest_received true))
  (def-keymap [n :silent] KEY Testfn)
  (t.k "capitalised"))

(def-test _def-autocmd
  (local CMD ":lua vim.g.zest_received = true")
  (local EVENT "User")
  (local SELECTOR "ZestEvent")

  (def-autocmd "User" "ZestEvent" ":lua vim.g.zest_received = true")
  (t.a "strings")

  (def-autocmd EVENT "ZestEvent" ":lua vim.g.zest_received = true")
  (t.a "var event")

  (def-autocmd "User" "ZestEvent" ":lua vim.g.zest_received = true")

  )

(each [k v (pairs _G.zest_tests)]
  (print (.. "" k))
  (v))
(clear)


;(def-test _vlua
;  (clear)
;  (let [v (vlua (fn []))]
;    (t.? (. _G._zest.v :_1) "store function")
;    (t.= v "v:lua._zest.v._1" "receive v:lua")))
;
;(def-test _vlua-format
;  (clear)
;  (let [vf (vlua-format ":call %s()" (fn []))]
;    (t.= vf ":call v:lua._zest.v._1()" "receive formatted v:lua")))
;
;(def-test _smart-concat
;  (local s "bar")
;  (t.= "foobar" (smart-concat "foobar") "just a string")
;  (t.= "bar" (smart-concat s) "just a var")
;  (t.= "foobar" (smart-concat ["foo" "bar"]) "xs with strings")
;  (t.= "foobarbaz" (smart-concat ["foo" s "baz"]) "xs with strings and vars")
;  (t.= "barbar" (smart-concat [s s]) "xs with vars")
;  (t.= "foo,bar,baz" (smart-concat ["foo" s "baz"] ",") "xs with strings and vars delimited")
;  (t.= "foo" (smart-concat "foo" ",") "string with a delimiter"))
;
;(def-test _def-keymap
;  (local KEY "<F4>")
;  (local CMD ":lua vim.g.zest_received = true<cr>")
;  (local TAB {KEY CMD})
;  (def-keymap-test "str -> str"
;    "<F4>" [n :silent] ":lua vim.g.zest_received = true<cr>")
;  (def-keymap-test "var -> var"
;    KEY [n :silent] CMD)
;
;  (def-keymap-pairs-test " -> tab {str str}"
;    [n :silent] {:<F4> ":lua vim.g.zest_received = true<cr>"})
;  (def-keymap-pairs-test " -> tab {var var}"
;    [n :silent] {KEY CMD})
;  ; TODO fails on passing a table as a var
;  ;(def-keymap-pairs-test " -> tab var"
;  ;  [n :silent] TAB)
;  )
;
;(def-test _def-keymap-fn
;  (local KEY "<F4>")
;  (def-keymap-fn-test "str -> bod"
;    "<F4>" [n :silent]
;    (set vim.g.zest_received true))
;  (def-keymap-fn-test "var -> bod"
;    KEY [n :silent]
;    (set vim.g.zest_received true)))
;
;(def-test _def-autocmd
;  (local EVENT "User")
;  (local SELECTOR "ZestTestUserEvent")
;  (local CMD ":lua vim.g.zest_received = true")
;  (def-autocmd-test "str str -> str"
;    "User" "ZestTestUserEvent" ":lua vim.g.zest_received = true")
;  (def-autocmd-test "var var -> var"
;    EVENT SELECTOR CMD))
;
;(def-test _def-autocmd-fn
;  (local EVENT "User")
;  (local SELECTOR "ZestTestUserEvent")
;  (def-autocmd-fn-test "str str -> bod"
;    "User" "ZestTestUserEvent"
;    (set vim.g.zest_received true))
;  (def-autocmd-fn-test "var var -> bod"
;    EVENT SELECTOR
;    (set vim.g.zest_received true)))


;(def-test _the-most-important-test
;  (t.= "dinosaur" "i wan't a radish" "i have a bad sense of humour"))
