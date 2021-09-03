; TODO
; def-command

;; util

(fn _hashfn? [x] (= (?. x 1 1) :hashfn))
(fn _fn? [x] (= (?. x 1 1) :fn))
(fn _partial? [x] (= (?. x 1 1) :partial))
(fn _capitalised? [s] (string.match (s:sub 1 1) "%u"))

(fn _zsm [...]
  "batch prefixed sym wrapper"
  (let [out []]
    (each [_ s (ipairs [...])]
      (table.insert out (gensym (.. "zest_" s))))
    (unpack out)))

(fn _zfn [f]
  "prepare a function for binding"
  (let [f (if (sequence? f)
            '(fn [] ,(unpack f))
            f)]
    (if (or (_fn? f)
              (_hashfn? f)
              (_partial? f)
              (and (sym? f)
                   (_capitalised? (tostring f))))
      f)))

(fn _zid []
  "ordered run time id"
  (let [(len* idx*) (_zsm :len :idx)
        g (sym "_G.zest.#")]
    '(let [,len* (. _G.zest :#)
           ,idx* (.. "_" ,len*)]
       (set ,g (+ ,len* 1))
       ,idx*)))

(fn _smart-concat [xs d]
  "concatenate literals in xs"
  (let [out []]
    (var last-string? false)
    (each [_ v (ipairs xs)]
      (let [string? (or (= (type v) :string)
                        (= (type v) :number))
            len (length out)]
        (if (and last-string?
                 string?)
          (tset out len (.. (. out len) d v))
          (table.insert out v))
        (set last-string? string?)))
    out))

(fn _concat [xs d]
  (let [d (or d "")]
    (var out [])
    (match xs
      (where s (or (= (type s) :string)
                   (= (type s) :number)))
      (table.insert out (tostring s))
      (where q (sym? q))
      (table.insert out `(if (= (type ,xs) :string)
                           ,xs
                           (table.concat ,xs ,d)))
      _ (set out (_smart-concat xs d)))
    (if (= (length out) 1)
      `,(unpack out)
      (if (= d "")
        `(.. ,(unpack out))
        `(table.concat ,out ,d)))))

;; helpers

; vlua

(fn _vlua [s f]
  "store a function in _G._zest and return its v:lua, formatting if needed"
  (let [idx* (_zsm :idx)]
    (list 'do
          (list 'local idx* (_zid))
          (list 'tset '_G.zest.user idx* f)
          (if s
            '(string.format ,s (.. "v:lua.zest.user." ,idx*))
            '(.. "v:lua.zest.user." ,idx*)))))

(fn vlua [x y]
  "prepare arguments for _vlua"
  (match [x y]
    [x nil] (_vlua nil x)
    [x   y] (_vlua x   y)))

(fn vim-g [k v]
  '(tset vim.g ,(tostring k) ,v))

;; options

; set-option

(fn _set-option [scope action key val]
  "complete vim.opt wrapper"
  (let [opt (.. "vim.opt" scope "." key)]
    (if action
      (list (sym (.. opt ":" action)) val)
      (list 'set (sym opt) val))))

(fn set-option [x y z]
  "prepare arguments for _set-option"
  (match [x y z]
    [x y nil] (_set-option "" nil (tostring x) (if (= nil y) true y))
    [x y   z] (let [(scope action) (match (tostring (. x 1))
                                     :l (values "_local"  (. x 2))
                                     :g (values "_global" (. x 2))
                                     _  (values ""        (. x 1)))]
                (_set-option scope action (tostring y) (if (= nil z) true z)))))

; get-option? vim.bo/vim.wo vim.o vim.go?

;; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts {:noremap true
              :expr    false}]
    (each [_ o (ipairs args)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn _keymap-id-lhs [lhs]
  (if (= (type lhs) :string)
    (string.gsub lhs "%W" (fn [c] (string.byte c)))
    '(string.gsub ,lhs "%W" (fn [c#] (string.byte c#)))))

; clean output uhh, demands a sacrifice
(fn _keymap-vlua [uid* uid opt* opt]
  (match [(= (type uid) :string)
          (and (not (sym? opt))
               (not (sym? (. opt :expr)))
               (not (= (. opt :expr) nil)))]
    [true true  ] (if opt.expr
                    (.. "v:lua.zest.keymap." uid "()")
                    (.. ":call v:lua.zest.keymap." uid "()<cr>"))
    [true false ] '(if (. ,opt :expr)
                     (.. "v:lua.zest.keymap." ,uid "()")
                     (.. ":call v:lua.zest.keymap." ,uid "()<cr>"))
    [false true ] (if opt.expr
                    '(.. "v:lua.zest.keymap." ,uid* "()")
                    '(.. ":call v:lua.zest.keymap." ,uid* "()<cr>"))
    _ '(if (. ,opt :expr)
         (.. "v:lua.zest.keymap." ,uid* "()")
         (.. ":call v:lua.zest.keymap." ,uid* "()<cr>"))))

(fn def-keymap-string [mod opt lhs rhs]
  (let [(mod* opt* lhs* rhs*) (_zsm :mod :opt :lhs :rhs)]
    '(do (comment "zest.def-autocmd-string")
       (let [,mod* ,mod
             ,opt* ,opt
             ,lhs* ,lhs
             ,rhs* ,rhs]
       (each [m# (string.gmatch ,mod* ".")]
         (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*))))))

(fn def-keymap-fn [mod opt lhs f]
  (let [(mod* opt* lhs* rhs* uid*) (_zsm :mod :opt :lhs :rhs :uid)
        uid (_concat [mod "_" (pick-values 1 (_keymap-id-lhs lhs))]) ; NOTE: gsub will add some garbage to the output
        rhs (_keymap-vlua uid* uid opt* opt)]
    '(do (comment "zest.def-keymap-fn")
       (let [,uid* ,uid
             ,mod* ,mod
             ,opt* ,opt
             ,lhs* ,lhs
             ,rhs* ,rhs]
         (tset _G.zest.keymap ,uid* ,f)
         (each [m# (string.gmatch ,mod* ".")]
           (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*))))))

(fn def-keymap-pairs [mod opt tab]
  (let [(mod* opt* tab* lhs* rhs*) (_zsm :mod :opt :tab :lhs :rhs)]
    '(do (comment "zest.def-keymap-pairs")
       (let [,mod* ,mod
             ,opt* ,opt
             ,tab* ,tab]
       (each [,lhs* ,rhs* (pairs ,tab*)]
         (each [m# (string.gmatch ,mod* ".")]
           (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*)))))))

(fn def-keymap [args lhs rhs]
  (let [(mod opt) (_keymap-options args)
        f (_zfn rhs)]
    (match [rhs f]
      [x   nil] (def-keymap-string mod opt lhs rhs)
      [x     y] (def-keymap-fn     mod opt lhs f)
      [nil nil] (def-keymap-pairs  mod opt lhs))))

;; autocmds

; def-augroup

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [definition (_concat ["augroup" name] " ")]
    (list 'do
          (list 'vim.cmd definition)
          (when (not dirty?)
            (list 'vim.cmd "autocmd!"))
          (when (> (length [...]) 0)
            (list 'do ...))
          (list 'vim.cmd "augroup END"))))

(fn def-augroup [name ...]
  (_create-augroup false name ...))

(fn def-augroup-dirty [name ...]
  (_create-augroup true name ...))

(fn def-autocmd-string [eve pat rhs]
  (let [(eve* pat* rhs*) (_zsm :eve :pat :rhs)]
    '(do (comment "zest.def-autocmd-string")
       (let [,eve* ,eve
             ,pat* ,pat
             ,rhs* ,rhs]
       (vim.cmd (.. "autocmd "
                    ,eve* " "
                    ,pat* " "
                    ,rhs*))))))

(fn def-autocmd-fn [eve pat f]
  (let [(eve* pat* rhs* idx*) (_zsm :eve :pat :rhs :idx)
        idx (_zid)
        rhs (list '.. ":call v:lua.zest.autocmd." idx* "()")]
    '(do (comment "zest.def-autocmd-fn")
       (let [,idx* ,idx
             ,eve* ,eve
             ,pat* ,pat
             ,rhs* ,rhs]
         (tset _G.zest.autocmd ,idx* ,f)
         (vim.cmd (.. "autocmd "
                      ,eve* " "
                      ,pat* " "
                      ,rhs*))))))

(fn def-autocmd [eve pat rhs]
  (let [f (_zfn rhs)
        eve (_concat eve ",")
        pat (_concat pat ",")]
    (if f
      (def-autocmd-fn     eve pat f)
      (def-autocmd-string eve pat rhs))))

{
 : vlua

 : set-option

 : def-keymap
 : def-keymap-string
 : def-keymap-fn
 : def-keymap-pairs

 : def-augroup
 : def-augroup-dirty

 : def-autocmd
 : def-autocmd-string
 : def-autocmd-fn

 }

