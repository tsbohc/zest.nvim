
; a very stripped down version of Olical/aniseed's test
; note: not for public use
; if you want to make tests, see aniseed's test suite instead

(local M {})

(fn M.= [x y description]
  (if (= x y)
    ;(print "")
    (print (.. "  + " description))
    (print (.. ">>>>>>>>>>>>>>> YOU SUCK! " description "\n" "    " (vim.inspect x) " != " (vim.inspect y)))))

(fn M.? [x description]
  (if x
    ;(print "")
    (print (.. "  + " description))
    (print (.. ">>>>>>>>>>>>>>> YOU SUCK! " description "\n" "    " (vim.inspect x)))))

M
