; TODO
; maybe i can get the filename somehow still? on the seq metatable?
; idx is index... save me from my equal sign alignment ocd
; FIXME vlua and vlua-format are still missing

(local fennel (require :zest.fennel))
(local inspect (require :zest.inspect))
(local lime (require :zest.lime.lime)) ; for some reason init.fnl was not being picked up as :zest.lime

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
  (let [f (if (fennel.sequence? f)
            `(fn [] ,(unpack f))
            f)]
    (if (or (_fn? f)
              (_hashfn? f)
              (_partial? f)
              (and (fennel.sym? f)
                   (_capitalised? (tostring f))))
      f)))

(fn _zid []
  "ordered run time id"
  (let [(len* idx*) (_zsm :len :idx)
        g (sym "_G.zest.#")]
    `(let [,len* (. _G.zest :#)
           ,idx* (.. "_" ,len*)]
       (set ,g (+ ,len* 1))
       ,idx*)))

; TODO rewrite with match
(fn _lit? [x]
  (if (fennel.sym? x)
    false
    (if (fennel.list? x)
      false
      (if (fennel.sequence? x)
        (do
          (each [_ v (ipairs x)]
            (if (not (_lit? v))
              (lua "return false")))
          true)
        (if (or (= (type x) :string)
                (= (type x) :number)
                (= x nil))
          true
          false)))))

; this is like 6x concat, 1x keymap_id + bare 1x keymap_vlua
; maybe i should just rewrite those as macros
(fn scall [f ...]
  (var safe? true)
  (each [_ x (ipairs [...])]
    (if (not (_lit? x))
      (set safe? false)))
  (if safe?
    (let [res ((. lime f) ...)]
      (if (and (not (fennel.sym? res))
               (not (fennel.list? res)))
        res
        (list (sym (.. "lime." f)) ...)))
    (list (sym (.. "lime." f)) ...)))

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

; TODO extract bindings into a separate macro and unwrap if possible
; micro opt?
;(fn _keymap-calls [mod ])

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts-xs args
        opts {:noremap true
              :expr    false}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn def-keymap-string [mod opt lhs rhs]
  (let [(mod* opt* lhs* rhs*) (_zsm :mod :opt :lhs :rhs)]
    `(do (comment "zest.def-autocmd-string")
       (let [,mod* ,mod
           ,opt* ,opt
           ,lhs* ,lhs
           ,rhs* ,rhs]
       (each [m# (string.gmatch ,mod* ".")]
         (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*))))))

; NB! syms go to run time, vals go to compile time
; note: we're not reusing def-keymap-string because we can't easily pass both symbols and values to another macro
(fn def-keymap-fn [mod opt lhs f]
  (let [(mod* opt* lhs* rhs* idx*) (_zsm :mod :opt :lhs :rhs :idx)
        idx (scall :keymap_id lhs mod)
        rhs (if (and (_lit? idx)
                     (not (sym? opt))
                     (not (sym? (. opt :expr))))
              (lime.keymap_vlua idx opt)
              (list 'lime.keymap_vlua idx* opt*))]
    `(do (comment "zest.def-keymap-fn")
       (let [,idx* ,idx
             ,mod* ,mod
             ,opt* ,opt
             ,lhs* ,lhs
             ,rhs* ,rhs]
         (tset _G.zest.keymap ,idx* ,f)
         (each [m# (string.gmatch ,mod* ".")]
           (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*))))))

(fn def-keymap-pairs [mod opt tab]
  (let [(mod* opt* tab* lhs* rhs*) (_zsm :mod :opt :tab :lhs :rhs)]
    `(do (comment "zest.def-keymap-pairs")
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
  (let [definition (scall :concat (fennel.sequence "augroup" name) " ")]
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

; TODO note to self: don't worry about splicing actual values of autocmd-sym as strings
; you'll have to rip that out when the new api comes anyway

; i could use -string in -fn, but i almost like them separate
(fn def-autocmd-string [eve pat rhs]
  (let [(eve* pat* rhs*) (_zsm :eve :pat :rhs)
        eve (scall :concat eve ",")
        pat (scall :concat pat ",")]
    `(do (comment "zest.def-autocmd-string")
       (let [,eve* ,eve
           ,pat* ,pat
           ,rhs* ,rhs]
       (vim.cmd (.. "autocmd "
                    ,eve* " "
                    ,pat* " "
                    ,rhs*))))))

(fn def-autocmd-fn [eve pat f]
  (let [(eve* pat* rhs* idx*) (_zsm :eve :pat :rhs :idx)
        eve (scall :concat eve ",")
        pat (scall :concat pat ",")
        idx (_zid)
        rhs (list '.. ":call v:lua.zest.autocmd." idx* "()")]
    `(do (comment "zest.def-autocmd-fn")
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
  (let [f (_zfn rhs)]
    (if f
      (def-autocmd-fn     eve pat f)
      (def-autocmd-string eve pat rhs))))


;(fn test []
;  (list 'print (tostring (gensym "_G.zest.ya"))))
;
;(fn test []
;  (list 'local* '(one# two#) (list 'foo)))

;(fn test []
;  (let [a (list 'print :w)]
;    (list 'print (fennel.list? a))))

(fn test []
  (let [s (sequence :a)]
    (list 'print (inspect s))))

{
 : test

 : set-option

 : def-keymap
 : def-keymap-string
 : def-keymap-fn
 : def-keymap-pairs

 : def-augroup
 : def-augroup-dirty
 : def-autocmd
 }

